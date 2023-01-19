#!/bin/sh

gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys $@ || \
gpg --batch --keyserver hkps://pgpkeys.eu --recv-keys $@ && \
gpg --yes --list-keys --fingerprint --with-colons | sed -E -n -e 's/^fpr:::::::::([0-9A-F]+):$/\1:6:/p' | gpg --import-ownertrust --yes
