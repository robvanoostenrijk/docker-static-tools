## Static Tools ##

When working with distroless containers in Docker, any debugging options of running containers are limited.
In these cases it can be partical to have a limited set of shell tools available in the container on a temporary basis.

`static-tools` is designed with this in mind. In essence its a docker image which contains a set of statically compiled tools, allowing them to easily be executed in a distroless environment.

Currently the following tools are included:

* Busybox - trimmed down to essentials
* nano - Alternative to vi
* cURL - curl with support for HTTP/2, TLS1.3 & brotli compression
* OpenSSL - OpenSSL client to test SSL connections and certificates
* strace - Trace system calls of running executables
* jq - Parse and Query JSON
* git - Push & pull from git (only SSH supported)
* brotli - (De)compress assets with brotli
* zopfli - Optimized gzip compression
* OpenSSH - scp, sftp & ssh
* bind - dig, nslookup & host
* file - Linux File magic
* ldd - LD dynamic library loading evaluation

## Usage ##

In order to use `static-tools` in a running container, a volume in docker needs to be populated:

    docker volume create static-tools
    docker run --rm -v static-tools:/volume static-tools /volume/

The above creates a new docker volume named `static-tools` and instructs the static-tools image to populate itself into the `/volume/` folder.

Additionally the `init.sh` script helps with this activity.

In order to make `static-tools` available on a container, it should be mapped to `/tools/`:

    docker run --rm -ti -v static-tools:/tools --name my-container my-container-image

After the application `my-container` is started, an interactive shell can be started using

    docker exec -ti `my-container` /tools/tools.sh
