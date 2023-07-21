# Steps to build Linux kernel for Firecracker microVM
1. Download [base kernel config](https://raw.githubusercontent.com/firecracker-microvm/firecracker/main/resources/guest_configs/$BASE_KERNEL_CONFIG)  from firecracker git repo
2. Clone [Firecracker repo](https://github.com/firecracker-microvm/firecracker.git)
3. Edit kernel .config file (description of additional modules below)
    ```
    sed -i 's/^# CONFIG_IP6_NF_IPTABLES=.*/CONFIG_IP6_NF_IPTABLES=y/' .config
    sed -i 's/^# CONFIG_NETFILTER_XT_MARK.*/CONFIG_NETFILTER_XT_MARK=y/' .config
    sed -i 's/^# CONFIG_NETFILTER_XT_MATCH_COMMENT.*/CONFIG_NETFILTER_XT_MATCH_COMMENT=y/' .config
    sed -i 's/^# CONFIG_NETFILTER_XT_MATCH_MULTIPORT.*/CONFIG_NETFILTER_XT_MATCH_MULTIPORT=y/' .config
    ```
4. Build Linux kernel
    ```
    ./tools/devtool build_kernel -c ".config" -n <num_of_cores>
    ```



## Description of Additional Modules Compiled into Kernel
CONFIG_IP6_NF_IPTABLES
    ip6tables is a general, extensible packet identification framework. Currently only the packet filtering and packet mangling subsystem for IPv6 use this, but connection tracking is going to follow. 
    
    Say 'Y' or 'M' here if you want to use either of those.


CONFIG_NETFILTER_XT_MARK
    This option adds the "MARK" target and "mark" match.

    Netfilter mark matching allows you to match packets based on the "nfmark" value in the packet. The target allows you to create rules in the "mangle" table which alter the netfilter mark (nfmark) field associated with the packet.

    Prior to routing, the nfmark can influence the routing method and can also be used by other subsystems to change their behavior.


config NETFILTER_XT_MATCH_COMMENT
    depends on NETFILTER_ADVANCED

    This option adds a `comment' dummy-match, which allows you to put
    comments in your iptables ruleset.

    If you want to compile it as a module, say M here and read
    <file:Documentation/kbuild/modules.rst>.  If unsure, say `N'.


config NETFILTER_XT_MATCH_MULTIPORT
    depends on NETFILTER_ADVANCED

    Multiport matching allows you to match TCP or UDP packets based on
    a series of source or destination ports: normally a rule can only
    match a single range of ports.

    To compile it as a module, choose M here.  If unsure, say N.


CONFIG_CRYPTO_CRC32_PCLMUL
    CRC32 CRC algorithm (IEEE 802.3)
    Architecture: x86 (32-bit and 64-bit) using: - PCLMULQDQ (carry-less multiplication)

    From Intel Westmere and AMD Bulldozer processor with SSE4.2 and PCLMULQDQ supported, the processor will support CRC32 PCLMULQDQ implementation using hardware accelerated PCLMULQDQ instruction. This option will create 'crc32-pclmul' module, which will enable any routine to use the CRC-32-IEEE 802.3 checksum and gain better performance as compared with the table implementation.


CONFIG_CRYPTO_CRC32C_INTEL
    In Intel processor with SSE4.2 supported, the processor will support CRC32C implementation using hardware accelerated CRC32 instruction. This option will create 'crc32c-intel' module, which will enable any routine to use the CRC32 instruction to gain performance compared with software implementation. Module will be crc32c-intel.


CONFIG_CRYPTO_GHASH_CLMUL_NI_INTEL
    This is the x86_64 CLMUL-NI accelerated implementation of GHASH, the hash function used in GCM (Galois/Counter mode).


CONFIG_CRYPTO_AES_NI_INTEL
    Use Intel AES-NI instructions for AES algorithm.

    AES cipher algorithms (FIPS-197). AES uses the Rijndael algorithm.

    Rijndael appears to be consistently a very good performer in both hardware and software across a wide range of computing environments regardless of its use in feedback or non-feedback modes. Its key setup time is excellent, and its key agility is good. Rijndael's very low memory requirements make it very well suited for restricted-space environments, in which it also demonstrates excellent performance. Rijndael's operations are among the easiest to defend against power and timing attacks.

    The AES specifies three key sizes: 128, 192 and 256 bits

    See http://csrc.nist.gov/encryption/aes/ for more information.

    In addition to AES cipher algorithm support, the acceleration for some popular block cipher mode is supported too, including ECB, CBC, LRW, XTS. The 64 bit version has additional acceleration for CTR and XCTR.


CONFIG_CRYPTO_CRYPTD
    This is a generic software asynchronous crypto daemon that converts an arbitrary synchronous software crypto algorithm into an asynchronous algorithm that executes in a kernel thread.


CONFIG_INPUT_EVDEV
    Say Y here if you want your input device events be accessible under char device 13:64+ - /dev/input/eventX in a generic way.

    To compile this driver as a module, choose M here: the module will be called evdev.


config NET_SCH_FQ_CODEL
    Say Y here if you want to use the FQ Controlled Delay (FQ_CODEL)
    packet scheduling algorithm.

    To compile this driver as a module, choose M here: the module
    will be called sch_fq_codel.

    If unsure, say N.


CONFIG_AUTOFS4_FS
    This name exists for people to just automatically pick up the new name of the autofs Kconfig option. All it does is select the new option name.

    It will go away in a release or two as people have transitioned to just plain AUTOFS_FS.