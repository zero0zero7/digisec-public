# Analysis of SIS usage

These analyses can be generated from SIS logs.

Currently, the relevant records can be found with:

```
egrep -i '(MaxDisconnection|Clean disconnection|sis-spawn\[|libpod-.{64}\.scope\".*nametype=DELETE)' /var/log/messages-YYYYMMDDD
```

If you want unique IP addresses, you might try something like this:

```sh
./stats < connect-20230105.log | egrep -o "172\.18\.[0-9]{,3}\.[0-9]{,3}" | sort | uniq
```

## Statistics collected

- For each session: start, end, container id, source ip
- Total sessions per day
- Max concurrent users per day
- Length of sessions (CDF)
