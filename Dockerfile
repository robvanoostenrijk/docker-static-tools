# syntax=docker/dockerfile:1.4
FROM alpine:latest AS builder

ARG PREFIX=/tools

ENV BIND_VERSION="9.19.8" \
    BROTLI_TAG="v1.0.9" \
    BUSYBOX_VERSION="1.36.0" \
    CURL_VERSION="7.87.0" \
    GIT_VERSION="2.39.1" \
    FILE_VERSION="5.44" \
    JQ_VERSION="1.6" \
    NANO_VERSION="7.1" \
    OPENSSH_VERSION="9.1p1" \
    OPENSSL_VERSION="3.0.7" \
    STRACE_VERSION="6.1"

COPY --link ["gpg-import.sh", "busybox.config", "/usr/src/"]

#
# Upfront all of the required downloads, speeding up cached layer rebuilds if needed
#
#ADD ["https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2", "/usr/src/busybox.tar.gz"]
#ADD ["https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2.sig", "/usr/src/busybox.sig"]
ADD ["http://ftp.icm.edu.pl/packages/busybox/busybox-${BUSYBOX_VERSION}.tar.bz2", "/usr/src/busybox.tar.bz2"]
ADD ["http://ftp.icm.edu.pl/packages/busybox/busybox-${BUSYBOX_VERSION}.tar.bz2.sig", "/usr/src/busybox.sig"]

ADD ["https://www.nano-editor.org/dist/v7/nano-${NANO_VERSION}.tar.xz", "/usr/src/nano.tar.xz"]
ADD ["https://www.nano-editor.org/dist/v7/nano-${NANO_VERSION}.tar.xz.asc", "/usr/src/nano.sig"]

ADD ["https://api.github.com/repos/google/brotli/tarball/master", "/usr/src/brotli.tar.gz"]
ADD ["https://api.github.com/repos/google/zopfli/tarball/master", "/usr/src/zopfli.tar.gz"]

ADD ["https://curl.haxx.se/ca/cacert.pem", "/usr/src/cacert.pem"]
ADD ["https://curl.haxx.se/ca/cacert.pem.sha256", "/usr/src/cacert.hash"]

ADD ["https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.xz", "/usr/src/curl.tar.xz"]
ADD ["https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.xz.asc", "/usr/src/curl.sig"]

ADD ["https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz", "/usr/src/openssl.tar.gz"]
ADD ["https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz.asc", "/usr/src/openssl.sig"]

ADD ["https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz", "/usr/src/openssh.tar.gz"]
ADD ["https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz.asc", "/usr/src/openssh.sig"]

ADD ["https://github.com/strace/strace/releases/download/v${STRACE_VERSION}/strace-${STRACE_VERSION}.tar.xz", "/usr/src/strace.tar.xz"]
ADD ["https://github.com/strace/strace/releases/download/v${STRACE_VERSION}/strace-${STRACE_VERSION}.tar.xz.asc", "/usr/src/strace.sig"]

ADD ["https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_VERSION}.tar.gz", "/usr/src/jq.tar.gz"]

ADD ["https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz", "/usr/src/git.tar.xz"]
ADD ["https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.sign", "/usr/src/git.sig"]

ADD ["http://ftp.astron.com/pub/file/file-${FILE_VERSION}.tar.gz", "/usr/src/file.tar.gz"]
ADD ["http://ftp.astron.com/pub/file/file-${FILE_VERSION}.tar.gz.asc", "/usr/src/file.sig"]

RUN <<EOF
set -x

apk add --no-cache \
  clang \
  cmake \
  curl \
  curl-dev \
  curl-static \
  g++ \
  git \
  gnupg \
  go \
  linux-headers \
  make \
  musl-dev \
  ncurses-dev \
  ncurses-static \
  nghttp2-dev \
  nghttp2-static \
  oniguruma \
  oniguruma-dev \
  openssl \
  openssl-dev \
  openssl-libs-static \
  perl \
  tar \
  xz \
  zlib-dev \
  zlib-static \
  --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main

EOF

#
# busybox
# Compile with defconfig, adjusting the static compilation settings afterwards
#
RUN <<EOF
set -x
/usr/src/gpg-import.sh C9E9416F76E610DBD09D040F47B70C55ACC9965B
gpg --verify /usr/src/busybox.sig /usr/src/busybox.tar.bz2 || exit 1
tar -jxf /usr/src/busybox.tar.bz2 -C /usr/src --one-top-level=busybox --strip-components=1
cd /usr/src/busybox
cp /usr/src/busybox.config /usr/src/busybox/.config

CC=clang make install CONFIG_PREFIX=${PREFIX}

EOF

#
# nano
#
RUN <<EOF
set -x
/usr/src/gpg-import.sh 168E6F4297BFD7A79AFD4496514BBE2EB8E1961F
gpg --verify /usr/src/nano.sig /usr/src/nano.tar.xz || exit 1
tar -xf /usr/src/nano.tar.xz -C /usr/src --one-top-level=nano --strip-components=1
cd /usr/src/nano
CC=clang LDFLAGS="-w -s -static" ./configure \
  --disable-extra \
  --disable-histories \
  --disable-libmagic \
  --disable-mouse \
  --disable-nanorc \
  --disable-operatingdir \
  --disable-speller \
  --enable-tiny \
  --enable-utf8 \
  --with-slang \
  --prefix=${PREFIX}
make -j`nproc`
cp src/nano ${PREFIX}/usr/bin
EOF

#
# brotli
#
RUN <<EOF
set -x
tar -xf /usr/src/brotli.tar.gz -C /usr/src --one-top-level=brotli --strip-components=1
cd /usr/src/brotli
mkdir out && cd out
CC=clang LDFLAGS="-w -s -static" cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF ..
cmake --build . --config Release --target brotli
cp brotli ${PREFIX}/usr/bin

EOF

#
# zopfli
#
RUN <<EOF
set -x
tar -xf /usr/src/zopfli.tar.gz -C /usr/src --one-top-level=zopfli --strip-components=1
cd /usr/src/zopfli
make LDFLAGS="-s -w -static" zopfli zopflipng
cp zopfli zopflipng ${PREFIX}/usr/bin

EOF

#
# curl
#
RUN <<EOF
set -x
mkdir -p ${PREFIX}/etc
cd /usr/src
sha256sum -c /usr/src/cacert.hash || exit 1
cp cacert.pem ${PREFIX}/etc
/usr/src/gpg-import.sh 27EDEAF22F3ABCEB50DB9A125CC908FDB71E12C2
gpg --verify /usr/src/curl.sig /usr/src/curl.tar.xz || exit 1
tar -xf /usr/src/curl.tar.xz -C /usr/src --one-top-level=curl --strip-component=1
cd /usr/src/curl
autoreconf -fi
CC=clang LDFLAGS="-w -s -static -all-static" PKG_CONFIG="pkg-config --static" ./configure \
  --prefix=${PREFIX} \
  --disable-dict \
  --disable-doh \
  --disable-gopher \
  --disable-imap \
  --disable-ldap \
  --disable-ldaps \
  --disable-manual \
  --disable-mqtt \
  --disable-pop3 \
  --disable-rtsp \
  --disable-shared \
  --disable-smb \
  --disable-smtp \
  --disable-sspi \
  --disable-telnet \
  --disable-tftp \
  --disable-threaded-resolver \
  --enable-static \
  --without-brotli \
  --with-ca-bundle=${PREFIX}/etc/cacert.pem \
  --with-openssl \
  --with-pic
make -j`nproc`
cp src/curl ${PREFIX}/usr/bin/curl

EOF

#
# OpenSSL
#
RUN <<EOF
set -x
/usr/src/gpg-import.sh DC7032662AF885E2F47F243F527466A21CA79E6D
gpg --verify /usr/src/openssl.sig /usr/src/openssl.tar.gz || exit 1
tar -xf /usr/src/openssl.tar.gz -C /usr/src --one-top-level=openssl --strip-component=1
cd /usr/src/openssl
CC=clang ./Configure \
  --static \
  -static \
  no-shared \
  no-tests \
  linux-generic64
make -j$(getconf _NPROCESSORS_ONLN)
strip apps/openssl
cp apps/openssl ${PREFIX}/usr/bin

EOF

#
# OpenSSH
#
RUN <<EOF
set -x
/usr/src/gpg-import.sh 7168B983815A5EEF59A4ADFD2A3F414E736060BA
gpg --verify /usr/src/openssh.sig /usr/src/openssh.tar.gz || exit 1
tar -zxf /usr/src/openssh.tar.gz -C /usr/src --one-top-level=openssh --strip-components=1
cd /usr/src/openssh
CC=clang ./configure \
  --prefix=${PREFIX}
sed -i -e 's/^LDFLAGS=\(.*\)$/LDFLAGS=\1 -s -w -static/' Makefile
make -j`nproc` ssh scp sftp
cp ssh scp sftp ${PREFIX}/usr/bin

EOF

#
# strace
#
RUN <<EOF
set -x
/usr/src/gpg-import.sh A8041FA839E16E36
gpg --verify /usr/src/strace.sig /usr/src/strace.tar.xz || exit 1
tar -xf /usr/src/strace.tar.xz -C /usr/src --one-top-level=strace --strip-components=1
cd /usr/src/strace
CC=clang CFLAGS="-Wno-unknown-warning-option -Wno-unused-function" LDFLAGS="-w -s -static" ./configure \
  --prefix=${PREFIX} \
  --disable-mpers
  make -j`nproc`
cp src/strace ${PREFIX}/usr/bin
EOF

#
# jq
#
RUN <<EOF
set -x
tar -xf /usr/src/jq.tar.gz -C /usr/src --one-top-level=jq --strip-components=1
cd /usr/src/jq
CC=clang LDFLAGS="-s -w -static -all-static" ./configure \
  --prefix=${PREFIX}
make -j`nproc`
cp jq ${PREFIX}/usr/bin

EOF

#
# yq
#
RUN <<EOF
set -x
mkdir /usr/src/yq
GOPATH=/usr/src/yq CGO_ENABLED=0 go install github.com/mikefarah/yq/v4@latest
#strip /usr/src/yq/bin/yq
cp /usr/src/yq/bin/yq ${PREFIX}/usr/bin

EOF

#
# q
#
RUN <<EOF
set -x
mkdir /usr/src/q
GOPATH=/usr/src/q CGO_ENABLED=0 go install github.com/natesales/q@latest
#strip /usr/src/q/bin/q
cp /usr/src/q/bin/q ${PREFIX}/usr/bin

EOF

#
# file
#
RUN <<EOF
set -x
/usr/src/gpg-import.sh BE04995BA8F90ED0C0C176C471112AB16CB33B3A
gpg --verify /usr/src/file.sig /usr/src/file.tar.gz || exit 1
tar -xf /usr/src/file.tar.gz -C /usr/src --one-top-level=file --strip-components=1
cd /usr/src/file

LDFLAGS="-s -w --static" CPPFLAGS="-static" CFLAGS="-static" ./configure \
  --prefix=${PREFIX} \
  --enable-static

make

cp src/file ${PREFIX}/usr/bin
mkdir -p ${PREFIX}/share/misc
cp magic/magic.mgc ${PREFIX}/share/misc/magic.mgc

EOF

#
# git
#
RUN <<EOF
set -x
/usr/src/gpg-import.sh E1F036B1FEE7221FC778ECEFB0B5E88696AFE6CB
xz -d /usr/src/git.tar.xz
gpg --verify /usr/src/git.sig /usr/src/git.tar || exit 1
tar -xf /usr/src/git.tar -C /usr/src --one-top-level=git --strip-components=1
cd /usr/src/git
CC=clang LDFLAGS="-s -w -static" ./configure \
  --prefix=${PREFIX} \
  --with-curl \
  --with-openssl \
  --without-tcltk
make -j`nproc`

cp git ${PREFIX}/usr/bin

EOF

COPY <<entrypoint.sh /scratchfs${PREFIX}/
#!${PREFIX}/bin/sh

set -e
export PATH=${PREFIX}/bin:${PREFIX}/usr/bin:\$PATH

if [ "\$1" == "volume" ]; then
	echo "[i] Populating into volume mapped directory \$2."

	if [ -d "\$2" ]; then
		cp -rv ${PREFIX}/entrypoint.sh ${PREFIX}/bin ${PREFIX}/etc ${PREFIX}/usr \$2
		echo "[i] Data copied and available in \$2."
	else
		echo "[!] Volume mapped directory \$2 does not exist."
	fi
else
	if [ \$# -eq 0 ]; then
		exec ${PREFIX}/bin/sh
	else
		${PREFIX}/bin/sh -c "\${@}"
	fi
fi
entrypoint.sh

RUN <<EOF
chmod a+x /scratchfs${PREFIX}/entrypoint.sh

ln -s ${PREFIX}/entrypoint.sh /scratchfs/entrypoint.sh
mv ${PREFIX}/* /scratchfs${PREFIX}

EOF

FROM scratch

COPY --from=builder [ "/scratchfs/", "/" ]

SHELL ["/entrypoint.sh"]
ENTRYPOINT [ "/entrypoint.sh" ]
