FROM alpine:latest AS build

ENV	BIND_VERSION="9.16.19" \
	BROTLI_VERSION="1.0.9" \
	BUSYBOX_VERSION="1.34.0" \
	CURL_VERSION="7.78.0" \
	GIT_VERSION="2.9.5" \
	FILE_VERSION="5.40" \
	JQ_VERSION="1.6" \
	NANO_VERSION="5.8" \
	OPENSSH_VERSION="8.6p1" \
	OPENSSL_VERSION="1.1.1k" \
	STRACE_VERSION="5.13" \
	ZOPFLI_VERSION="1.0.3"

RUN	set -x && \
	apk add --no-cache \
	autoconf \
	automake \
	bash \
	build-base \
	cmake \
	curl \
	gawk \
	git \
	gnupg \
	libtool \
	libssh \
	libssh-dev \
	libuv \
	libuv-dev \
	libuv-static \
	linux-headers \
	musl-dev \
	ncurses-dev \
	ncurses-static \
	nghttp2-dev \
	nghttp2-static \
	oniguruma \
	oniguruma-dev \
	openssl-dev \
	openssl-libs-static \
	perl \
	tcl \
	tcl-dev \
	xz \
	zlib-dev \
	zlib-static \
	--repository=http://dl-cdn.alpinelinux.org/alpine/edge/main && \
	mkdir -p /build && \
	set -- \
	C9E9416F76E610DBD09D040F47B70C55ACC9965B \
	27EDEAF22F3ABCEB50DB9A125CC908FDB71E12C2 \
	296D6F29A020808E8717A8842DB5BD89A340AEB7 \
	7168B983815A5EEF59A4ADFD2A3F414E736060BA \
	8657ABB260F056B1E5190839D9C4D26D0E604491 \
	96E07AF25771955980DAD10020D04E5A713660A7 \
	BFD009061E535052AD0DF2150D28D4D2A0ACE884 \
	E3FF2839C048B25C084DEBE9B26995E310250568 \
	E9AB6E79233C0416E8993F450C03AFA90A5967C4 \
	BE04995BA8F90ED0C0C176C471112AB16CB33B3A && \
	gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys $@ || \
	gpg --batch --keyserver hkps://peegeepee.com --recv-keys $@ && \
	gpg --yes --list-keys --fingerprint --with-colons | sed -E -n -e 's/^fpr:::::::::([0-9A-F]+):$/\1:6:/p' | gpg --import-ownertrust --yes

COPY ["busybox.config", "/build/"]

RUN set -x && \
	#
	# busybox
	#
	curl --location --silent --output /build/busybox-${BUSYBOX_VERSION}.tar.bz2 https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2 && \
	curl --location --silent --output /build/busybox-${BUSYBOX_VERSION}.tar.bz2.sig https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2.sig && \
	tar -jxf /build/busybox-${BUSYBOX_VERSION}.tar.bz2 -C /build && \
	gpg --verify /build/busybox-${BUSYBOX_VERSION}.tar.bz2.sig && \
	rm /build/busybox-${BUSYBOX_VERSION}.tar.bz2 /build/busybox-${BUSYBOX_VERSION}.tar.bz2.sig && \
	cd /build/busybox-${BUSYBOX_VERSION} && \
	cp /build/busybox.config /build/busybox-${BUSYBOX_VERSION}/.config && \
	make install CONFIG_PREFIX=/tools

RUN	set -x && \
	#
	#	nano
	#	
	curl --location --silent --output /build/nano-${NANO_VERSION}.tar.xz https://www.nano-editor.org/dist/v$(echo $NANO_VERSION | head -c 1)/nano-${NANO_VERSION}.tar.xz && \
	curl --location --silent --output /build/nano-${NANO_VERSION}.tar.xz.asc https://www.nano-editor.org/dist/v$(echo $NANO_VERSION | head -c 1)/nano-${NANO_VERSION}.tar.xz.asc && \
	gpg --verify /build/nano-${NANO_VERSION}.tar.xz.asc && \
	tar -xf /build/nano-${NANO_VERSION}.tar.xz -C /build && \
	rm /build/nano-${NANO_VERSION}.tar.xz /build/nano-${NANO_VERSION}.tar.xz.asc && \
	cd /build/nano-${NANO_VERSION} && \
	./configure \
	--disable-extra \
	--disable-histories \
	--disable-libmagic \
	--disable-mouse \
	--disable-nanorc \
	--disable-operatingdir \
	--disable-speller \
	--enable-tiny \
	--enable-utf8 \
	--prefix=/tools && \
	make -j`nproc` LDFLAGS="-w -s --static" install && \
	rm -f -r /build/nano-${NANO_VERSION} /tools/bin/rnano

RUN	set -x && \
	#
	#	brotli
	#
	git clone https://github.com/bagder/libbrotli.git /build/libbrotli && \
	cd /build/libbrotli && \
	./autogen.sh && \
	./configure && \
	make LDFLAGS="-w -s -static" install && \
	#
	#	curl
	#
	curl --location --silent --output /build/curl-${CURL_VERSION}.tar.xz https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.xz && \
	curl --location --silent --compressed --output /build/curl-${CURL_VERSION}.tar.xz.asc https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.xz.asc && \
	gpg --verify /build/curl-${CURL_VERSION}.tar.xz.asc && \
	tar -xf /build/curl-${CURL_VERSION}.tar.xz -C /build && \
	rm /build/curl-${CURL_VERSION}.tar.xz /build/curl-${CURL_VERSION}.tar.xz.asc && \
	cd /build/curl-${CURL_VERSION} && \
	./configure \
	--prefix=/tools \
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
	--with-ca-bundle=/tools/etc/cacert.pem \
	--with-openssl \
	--with-pic \
	--without-libidn && \
	make -j`nproc` V=1 LDFLAGS="-w -s -static -all-static" install && \
	rm -f -r /build/curl-${CURL_VERSION} /build/libbrotli

RUN	set -x && \
	#
	#	OpenSSL
	#
	curl --location --silent --output /build/openssl-${OPENSSL_VERSION}.tar.gz https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
	curl --location --silent --output /build/openssl-${OPENSSL_VERSION}.tar.gz.asc https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz.asc && \
	gpg --verify /build/openssl-${OPENSSL_VERSION}.tar.gz.asc && \
	tar -zxf /build/openssl-${OPENSSL_VERSION}.tar.gz -C /build && \
	rm /build/openssl-${OPENSSL_VERSION}.tar.gz /build/openssl-${OPENSSL_VERSION}.tar.gz.asc && \
	cd /build/openssl-${OPENSSL_VERSION} && \
	./config \
	--static \
	-static \
	no-shared \
	no-tests \
	--prefix=/tools && \
	make -j`nproc` && \
	make install_sw && \
	rm -f -r /build/openssl-${OPENSSL_VERSION} /tools/include /tools/lib /tools/bin/c_rehash && \
	strip /tools/bin/openssl

RUN	set -x && \
	#
	#	strace
	#
	curl --location --silent --output /build/strace-${STRACE_VERSION}.tar.xz https://github.com/strace/strace/releases/download/v${STRACE_VERSION}/strace-${STRACE_VERSION}.tar.xz && \
	curl --location --silent --output /build/strace-${STRACE_VERSION}.tar.xz.asc https://github.com/strace/strace/releases/download/v${STRACE_VERSION}/strace-${STRACE_VERSION}.tar.xz.asc && \
	gpg --verify /build/strace-${STRACE_VERSION}.tar.xz.asc && \
	tar -xf /build/strace-${STRACE_VERSION}.tar.xz -C /build && \
	rm /build/strace-${STRACE_VERSION}.tar.xz /build/strace-${STRACE_VERSION}.tar.xz.asc && \
	cd /build/strace-${STRACE_VERSION} && \
	./configure \
	--prefix=/tools \
	--disable-mpers && \
	make -j`nproc` LDFLAGS='-w -s -static' install && \
	rm -f -r /build/strace-${STRACE_VERSION} /tools/bin/strace-log-merge

RUN	set -x && \
	#
	#	jq
	#
	curl --location --silent --output /build/jq-${JQ_VERSION}.tar.gz https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_VERSION}.tar.gz && \
	tar -zxf /build/jq-${JQ_VERSION}.tar.gz -C /build && \
	rm /build/jq-${JQ_VERSION}.tar.gz && \
	cd /build/jq-${JQ_VERSION} && \
	./configure \
	--prefix=/tools && \
	make -j`nproc` LDFLAGS="-s -w -static -all-static" install && \
	rm -f -r /build/jq-${JQ_VERSION}

RUN set -x && \
	#
	#	git
	#
	curl --location --silent --output /build/git-${GIT_VERSION}.tar.xz https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz && \
	curl --location --silent --compressed --output /build/git-${GIT_VERSION}.tar.sign https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.sign && \
	xz -d /build/git-${GIT_VERSION}.tar.xz && \
	gpg --verify /build/git-${GIT_VERSION}.tar.sign && \
	tar -xf /build/git-${GIT_VERSION}.tar -C /build && \
	rm /build/git-${GIT_VERSION}.tar /build/git-${GIT_VERSION}.tar.sign && \
	cd /build/git-${GIT_VERSION} && \
	./configure \
	--prefix=/tools && \
	make -j`nproc` LDFLAGS="-s -w -static" install && \
	rm -f -r /build/git-${GIT_VERSION} /tools/bin/git-* /tools/bin/gitk 

RUN set -x && \
	#
	#	brotli
	#
	curl --location --silent --output /build/brotli-${BROTLI_VERSION}.tar.gz https://github.com/google/brotli/archive/refs/tags/v${BROTLI_VERSION}.tar.gz && \
	tar -zxf /build/brotli-${BROTLI_VERSION}.tar.gz -C /build && \
	rm /build/brotli-${BROTLI_VERSION}.tar.gz && \
	cd /build/brotli-${BROTLI_VERSION} && \
	./configure-cmake \
	--prefix=/tools \
	--disable-debug && \
	cmake -DCMAKE_EXE_LINKER_FLAGS="-s -w -static" . && \
	make install && \
	rm -f -r /build/brotli-${BROTLI_VERSION}

RUN set -x && \
	#
	#	zopfli
	#
	curl --location --silent --output /build/zopfli-${ZOPFLI_VERSION}.tar.gz https://github.com/google/zopfli/archive/refs/tags/zopfli-${ZOPFLI_VERSION}.tar.gz && \
	tar -zxf /build/zopfli-${ZOPFLI_VERSION}.tar.gz -C /build && \
	rm /build/zopfli-${ZOPFLI_VERSION}.tar.gz && \
	cd /build/zopfli-zopfli-${ZOPFLI_VERSION} && \
	make LDFLAGS="-s -w -static" zopfli zopflipng && \
	cp /build/zopfli-zopfli-${ZOPFLI_VERSION}/zopfli /build/zopfli-zopfli-${ZOPFLI_VERSION}/zopflipng /tools/bin && \
	rm -f -r /build/zopfli-zopfli-${ZOPFLI_VERSION}

RUN	set -x && \
	#
	#	OpenSSH
	#
	curl --location --silent --output /build/openssh-${OPENSSH_VERSION}.tar.gz https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz && \
	curl --location --silent --output /build/openssh-${OPENSSH_VERSION}.tar.gz.asc https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz.asc && \
	gpg --verify /build/openssh-${OPENSSH_VERSION}.tar.gz.asc && \
	tar -zxf /build/openssh-${OPENSSH_VERSION}.tar.gz -C /build && \
	rm /build/openssh-${OPENSSH_VERSION}.tar.gz /build/openssh-${OPENSSH_VERSION}.tar.gz.asc && \
	cd /build/openssh-${OPENSSH_VERSION} && \
	./configure \
	--prefix=/tools && \
	sed -i -e 's/^LDFLAGS=\(.*\)$/LDFLAGS=\1 -s -w -static/' Makefile && \
	make -j`nproc` ssh scp sftp && \
	make install && \
	rm -f -r /build/openssh-${OPENSSH_VERSION} /tools/bin/ssh-* /tools/libexec/ssh-* /tools/libexec/sftp-* /tools/sbin/sshd

RUN set -x && \
	#
	#	bind
	#
	curl --location --silent --output /build/bind-${BIND_VERSION}.tar.xz https://downloads.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.xz && \
	curl --location --silent --output /build/bind-${BIND_VERSION}.tar.xz.asc https://downloads.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.xz.asc && \
	gpg --verify /build/bind-${BIND_VERSION}.tar.xz.asc && \
	tar -xf /build/bind-${BIND_VERSION}.tar.xz -C /build && \
	rm /build/bind-${BIND_VERSION}.tar.xz /build/bind-${BIND_VERSION}.tar.xz.asc && \
	cd /build/bind-${BIND_VERSION} && \
	./configure \
	--without-python \
	--disable-linux-caps \
	--prefix=/tools && \
	make LDFLAGS='-s -w -static' -C lib/dns && \
	make LDFLAGS='-s -w -static' -C lib/bind9 && \
	make LDFLAGS='-s -w -static' -C lib/isc && \
	make LDFLAGS='-s -w -static' -C lib/isccfg && \
	make LDFLAGS='-s -w -static' -C lib/irs && \
	make LDFLAGS='-s -w -static' -C bin/dig && \
	make -C bin/dig install && \
	rm -f -r /build/bind-${BIND_VERSION}

RUN set -x && \
	#
	#	file
	#
	curl --location --silent --output /build/file-${FILE_VERSION}.tar.gz ftp://ftp.astron.com/pub/file/file-${FILE_VERSION}.tar.gz && \
	curl --location --silent --output /build/file-${FILE_VERSION}.tar.gz.asc ftp://ftp.astron.com/pub/file/file-${FILE_VERSION}.tar.gz.asc && \
	tar -zxf /build/file-${FILE_VERSION}.tar.gz -C /build && \
	gpg --verify /build/file-${FILE_VERSION}.tar.gz.asc && \
	rm /build/file-${FILE_VERSION}.tar.gz /build/file-${FILE_VERSION}.tar.gz.asc && \
	cd /build/file-${FILE_VERSION} && \
	LDFLAGS="-s -w --static" CPPFLAGS="-static" CFLAGS="-static" ./configure --prefix=/tools --enable-static && \
	make install && \
	rm -f -r /build/file-${FILE_VERSION}

RUN	ln -s / /tools/tools && \
	find /tools -type d -maxdepth 1 ! -name "tools" ! -name "bin" ! -name "libexec" ! -name "sbin" ! -name "share" -exec rm -fR {} \; && \
	find /tools/share -type d -maxdepth 1 ! -name "share" ! -name "misc" -exec rm -fR {} \; && \
	mkdir -p /tools/etc && \
	curl --location --silent --compressed --output /tools/etc/cacert.pem https://curl.haxx.se/ca/cacert.pem && \
	curl --location --silent --compressed --output /tools/etc/cacert.pem.sha256 https://curl.haxx.se/ca/cacert.pem.sha256 && \
	cd /tools/etc && \
	sha256sum -c /tools/etc/cacert.pem.sha256 && \
	rm /tools/etc/cacert.pem.sha256 && \
	cp -r /etc/terminfo /tools/etc && \
	mkdir -p /tools/lib && \
	cp /lib/ld-musl-* /tools/lib

COPY ["tools/", "/tools/"]

FROM	scratch

ENV	PATH=$PATH:/tools/bin

COPY	--from=build ["/tools", "/"]

# Allow container to be mapped in either / and /tools

# Preparing a volume to attach:
#
#	docker volume create static-tools
#	docker run --rm -v static-tools:/volume static-tools /volume/
#
# Run a sample container with the volume mounted in /tools
# docker \
#	run --rm -ti \
#	-v static-tools:/tools \
#	--name content-service \
#	content-service $1
#
# Remove the created volume:
# 	docker volume rm static-tools
#
# Attach and run the tools shell:
#
#	docker exec -it gateway /tools/tools.sh
ENTRYPOINT ["/tools.sh"]
