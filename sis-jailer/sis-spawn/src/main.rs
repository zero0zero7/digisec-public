use std::collections::BTreeMap;
use std::fmt;
use std::net::{IpAddr, SocketAddr};
use std::str::FromStr;
use std::time::{Duration, SystemTime};

use axum::{
    extract::{Query, State},
    http::{header::HeaderMap, StatusCode},
    response::Redirect,
    routing::get,
    Router,
};
use once_cell::sync::OnceCell;
use serde::{de, Deserialize, Deserializer};
use tokio::{process::Command, sync::RwLock};
use tracing::{debug, info};

const PODMAN: &str = "/usr/bin/podman";

static SECRET: OnceCell<[u8; 16]> = OnceCell::new();

lazy_static::lazy_static! {
    static ref STARTUPS: RwLock<BTreeMap<String, (SystemTime, Option<SystemTime>)>> =  Default::default();
}

#[derive(Clone, Debug)]
struct AppState {
    guac_host: String,
    ctr_bind_addr: IpAddr,
}

/// Sign and encrypt according to the possibly insecure Guacamole
/// encrypted JSON format.
fn sign_encrypt(key: &[u8; 16], doc: &[u8]) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    use aes::Aes128;
    use cbc::Encryptor;
    use cipher::{block_padding::Pkcs7, BlockEncryptMut, KeyIvInit};
    use hmac::{Hmac, Mac};
    use sha2::Sha256;

    let mut mac = Hmac::<Sha256>::new_from_slice(key)?;
    mac.update(doc);
    let mut message: Vec<_> = mac.finalize().into_bytes().as_slice().into();
    message.extend_from_slice(doc);
    let plaintext_len = message.len();
    message.resize(((plaintext_len + 16) / 16) * 16, 0);
    debug!("sign_encrypt len: {} {}", message.len(), plaintext_len);
    let iv = [0x0; 16];
    Encryptor::<Aes128>::new(key.into(), &iv.into())
        .encrypt_padded_mut::<Pkcs7>(&mut message, plaintext_len)?;
    Ok(message)
}

fn generate_vnc_pass() -> Result<String, Box<dyn std::error::Error>> {
    use rand::Fill;
    let mut rng = rand::thread_rng();
    // 128 bits of random data should be overkill for a day-long browser session.
    let mut bytes = [0; 16];
    bytes.try_fill(&mut rng)?;
    Ok(hex::encode(bytes))
}

#[tokio::main]
async fn main() {
    env_logger::init();

    let ev = std::env::var("GUAC_ENCRYPTED_JSON_SECRET")
        .expect("GUAC_ENCRYPTED_JSON_SECRET must be set");
    let bytes = hex::decode(ev).unwrap();
    SECRET.set(bytes.try_into().unwrap()).unwrap();

    let guac_host: String = std::env::var("GUAC_HOST")
        .expect("GUAC_HOST must be set, e.g. 'http://localhost:8080/guacamole'");

    let listen_sockaddr = std::env::var("LISTEN_ADDR").unwrap_or("0.0.0.0:12000".to_string());
    let sockaddr = listen_sockaddr
        .parse()
        .expect("Invalid LISTEN_ADDR; try e.g. '0.0.0.0:12000'");

    let ctr_bind_addr: IpAddr = std::env::var("CTR_BIND_ADDR")
        .unwrap_or("0.0.0.0".to_string())
        .parse()
        .expect("Invalid CTR_BIND_ADDR; try e.g. '0.0.0.0'");

    let app_state = AppState {
        guac_host,
        ctr_bind_addr,
    };

    info!("Binding to {}", &sockaddr);

    let app = Router::new()
        .route("/login", get(new_browser))
        .with_state(app_state);
    axum::Server::bind(&sockaddr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}

const CTR_PARAMS: &[&str] = &[
    "--read-only",
    "--cpus=2",
    "--memory=2g",
    "--cap-drop=all",
    "--cap-add=sys_ptrace",
    "--cap-add=sys_chroot",
    "--tmpfs=/tmp:rw,noexec,nosuid,nodev",
    "--tmpfs=/var/tmp:rw,noexec,nosuid,nodev",
    "--tmpfs=/run:rw,noexec,nosuid,nodev",
    // Note: the following line makes it impossible to podman exec -t
    "--tmpfs=/dev:rw,noexec,nosuid,nodev,size=65536k,mode=755",
    "--log-driver=journald",
    "--log-opt=tag={{.ID}}",
];

const DEFAULT_WIDTH: u16 = 1366;
const DEFAULT_HEIGHT: u16 = 654;

const MAX_WIDTH: u16 = 1920;
const MAX_HEIGHT: u16 = 1280;

fn reasonable_sz(client_width: Option<u16>, client_height: Option<u16>) -> (u16, u16) {
    if let Some(mut width) = client_width {
        if let Some(mut height) = client_height {
            while width > MAX_WIDTH {
                width /= 2;
                height /= 2;
            }
            while height > MAX_HEIGHT {
                height /= 2;
                width /= 2;
            }

            if width > 0 && height > 0 {
                return (width, height);
            }
        }
    }

    (DEFAULT_WIDTH, DEFAULT_HEIGHT)
}

struct SpawnedContainer {
    id: [u8; 32],
    addr: SocketAddr,
    vnc_password: String,
    width: u16,
    height: u16,
    started: bool,
}

impl SpawnedContainer {
    /// Spawns a container, returning its SHA256 ID.
    #[tracing::instrument]
    async fn create(
        image_name: &str,
        bind_addr: IpAddr,
        width: Option<u16>,
        height: Option<u16>,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        let computed_sz = reasonable_sz(width, height);
        let vnc_password = generate_vnc_pass().unwrap();
        let ctr = Command::new(PODMAN)
            .arg("create")
            .arg("--rm")
            .args(CTR_PARAMS)
            .arg(format!("-e VNCPASSWD={}", vnc_password))
            .arg(format!("-p={}::5920", bind_addr))
            .arg(format!("-e VIEWPORT_WIDTH={}", computed_sz.0))
            .arg(format!("-e VIEWPORT_HEIGHT={}", computed_sz.1))
            .arg(image_name)
            .output()
            .await?;

        debug!("status {:?}", ctr);
        let ctr_id = std::str::from_utf8(&ctr.stdout)?.trim().to_string();
        let id: [u8; 32] = hex::decode(&ctr_id)?
            .try_into()
            .expect("Expected SHA256 hash from podman");

        let port = Command::new(PODMAN)
            .arg("inspect")
            // To inspect a non-running container
            .arg("--format={{ (index (index .NetworkSettings.Ports \"5920/tcp\") 0).HostPort }}")
            .arg(&ctr_id)
            .output()
            .await?;
        debug!("{:?}", port);
        let port = std::str::from_utf8(&port.stdout)?.trim().parse()?;

        let addr = SocketAddr::new(bind_addr, port);

        Ok(Self {
            id,
            addr,
            vnc_password,
            width: computed_sz.0,
            height: computed_sz.1,
            started: false,
        })
    }

    async fn start(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        Command::new(PODMAN)
            .arg("start")
            .arg(&self.id_string())
            .output()
            .await?;
        self.started = true;

        Ok(())
    }

    fn guac_string(&self) -> String {
        format!(
            r#"{{"username":"","connections":{{"SIS":{{"protocol":"vnc","parameters":{{"hostname":"{}","port":"{}","password":"{}","disable-paste":true}}}}}}}}"#,
            self.addr.ip(),
            self.addr.port(),
            self.vnc_password,
        )
    }

    fn guac_json_enc(&self, secret: &[u8; 16]) -> String {
        let ciphertext = sign_encrypt(secret, self.guac_string().as_bytes()).unwrap();
        let b64 = base64::encode(ciphertext);
        urlencoding::encode(&b64).into_owned()
    }

    fn id_string(&self) -> String {
        hex::encode(self.id)
    }
}

const MAX_STARTUPS_EXCEEDED_MSG: &str =
    "You have attempted to spawn too many SIS browsers in the last 5 minutes.";

#[derive(Debug, Deserialize)]
struct Params {
    #[serde(default, deserialize_with = "empty_string_as_none")]
    width: Option<u16>,
    #[serde(default, deserialize_with = "empty_string_as_none")]
    height: Option<u16>,
}

/// Serde deserialization decorator to map empty Strings to None,
fn empty_string_as_none<'de, D, T>(de: D) -> Result<Option<T>, D::Error>
where
    D: Deserializer<'de>,
    T: FromStr,
    T::Err: fmt::Display,
{
    let opt = Option::<String>::deserialize(de)?;
    match opt.as_deref() {
        None | Some("") => Ok(None),
        Some(s) => FromStr::from_str(s).map_err(de::Error::custom).map(Some),
    }
}

#[tracing::instrument(level = "debug")]
async fn new_browser(
    headers: HeaderMap,
    params: Query<Params>,
    State(app_state): State<AppState>,
) -> Result<Redirect, (StatusCode, &'static str)> {
    use std::collections::btree_map::Entry;

    let addr = headers.get("X-Forwarded-For").unwrap().to_str().unwrap();
    debug!("Connection from {}", addr);

    let now = SystemTime::now();
    match STARTUPS.write().await.entry(addr.to_string()) {
        Entry::Vacant(e) => {
            e.insert((now, None));
        }
        Entry::Occupied(mut e) => {
            // (latest, previous)
            if let Some(old) = e.get().1 {
                if now.duration_since(old).expect("must be earlier") < Duration::from_secs(300) {
                    // MaxStartups exceeded!
                    return Err((StatusCode::TOO_MANY_REQUESTS, MAX_STARTUPS_EXCEEDED_MSG));
                }
            }

            // OK, update startups
            let prev = e.get().0;
            *e.get_mut() = (now, Some(prev));
        }
    }

    let mut ctr = SpawnedContainer::create(
        "localhost/sisclient",
        app_state.ctr_bind_addr,
        params.width,
        params.height,
    )
    .await
    .unwrap();
    ctr.start().await.unwrap();
    info!(
        "spawned ctr {} on {:?} for {}",
        ctr.id_string(),
        ctr.addr,
        addr
    );

    let uri = format!(
        "{}/?data={}",
        app_state.guac_host,
        ctr.guac_json_enc(SECRET.get().unwrap())
    );
    Ok(Redirect::to(&uri))
}
