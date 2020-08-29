## IQFeed Docker

A dockerized IQFeed client running on Wine. This version is headless and does not require nodejs or python.
The iqconnect binary is patched to listen for non-local connections on the default ports.
Based on `i386/ubuntu:bionic` with fixed missing dependencies.

Usage  
-----
Clone this repository and build the image:
```
git clone https://github.com/denniskupec/iqfeed-docker.git
cd iqfeed-docker
docker build . -t iqfeed
```
Then run it:
```
docker run -d \
    -e IQFEED_LOGIN=?????? \
    -e IQFEED_PASSWORD=?????? \
    -p 5009:5009 -p 5901:5901 -p 9100:9100 -p 9300:9300 \
    -v /var/log/iqfeed:/root/DTN/IQFeed \
    iqfeed
```

The client is set to log only errors by default.
Set the `IQFEED_LOG_LEVEL` environment variable to change it:
- `0xB002` = none
- `0x0001` = all (includes data, can affect performance)
- `0xA88A` = all requests
- `0xB222` = only errors
- `0xB332` = errors and system messages
- `0xF222` = errors and debug messages
-----
Some information taken from [jaikumarm/docker-iqfeed](https://github.com/jaikumarm/docker-iqfeed).
