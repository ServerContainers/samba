FROM debian:stretch

RUN export samba_version=4.9.4 \
 && export DEBIAN_FRONTEND=noninteractive \
 \
 && apt-get -q -y update \
 && apt-get -q -y install build-essential \
                          wget \
 && apt-get -q -y install acl \
                          attr \
                          autoconf \
                          bison \
                          build-essential \
                          debhelper \
                          dnsutils \
                          docbook-xml \
                          docbook-xsl \
                          flex \
                          gdb \
                          krb5-user \
                          libacl1-dev \
                          libaio-dev \
                          libattr1-dev \
                          libblkid-dev \
                          libbsd-dev \
                          libcap-dev \
                          libcups2-dev \
                          libgnutls28-dev \
                          libjson-perl \
                          libldap2-dev \
                          libncurses5-dev \
                          libpam0g-dev \
                          libparse-yapp-perl \
                          libpopt-dev \
                          libreadline-dev \
                          libjansson-dev \
                          libarchive-dev \
                          libgpgme11-dev \
                          libtracker-sparql-1.0-dev \
                          libtracker-miner-1.0-dev \
                          perl \
                          perl-modules \
                          pkg-config \
                          procps \
                          python-all-dev \
                          python-dev \
                          python-dnspython \
                          python-crypto \
                          python-gpgme \
                          xsltproc \
                          zlib1g-dev \
 \
 && apt-get -q -y clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 \
 && wget https://download.samba.org/pub/samba/stable/samba-${samba_version}.tar.gz \
 && tar xvf samba-${samba_version}.tar.gz \
 && rm samba-${samba_version}.tar.gz \
 \
 && cd samba-${samba_version} \
 && ./configure --prefix=/ --enable-spotlight --without-ldb-lmdb \
 && make \
 && make install \
 \
 && touch /var/locks/registry.tdb \
 && cp examples/smb.conf.default /etc/smb.conf \
 && cd - \
 \
 && rm -rf samba-${samba_version}

VOLUME ["/shares"]

EXPOSE 139 445

COPY scripts /usr/local/bin/

HEALTHCHECK CMD ["docker-healthcheck.sh"]
ENTRYPOINT ["entrypoint.sh"]

CMD [ "bash", "-c", "smbd -FS -d 2 < /dev/null" ]
