FROM ubuntu:20.04 AS main

LABEL maintainer="Star Lab <info@starlab.io>"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        bash \
        bc \
        bison \
        build-essential \
        ccache \
        flex \
        gcc-8 \
        git \
        libelf-dev \
        libssl-dev \
        openssh-server \
        pigz \
        python \
        python3 \
        qemu \
        qemu-kvm \
        qemu-system-x86 \
        remake \
        rpm \
        sudo \
        vim \
        wget \
        zip \
        && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists* /tmp/* /var/tmp/*

RUN ln -sf /usr/bin/gcc-8 /usr/bin/gcc

ARG GO_VER=1.14.2
ARG GO_TARBALL=go${GO_VER}.linux-amd64.tar.gz
ENV GOPATH=/usr/local/gopath
ENV GOROOT=/usr/local/goroot
ENV PATH=${GOROOT}/bin:${GOPATH}/bin:${PATH}
RUN wget -nv "https://dl.google.com/go/${GO_TARBALL}" && \
    mkdir -p "${GOPATH}" && \
    mkdir -p "${GOROOT}" && \
    tar xf "${GO_TARBALL}" --strip-components=1 -C "${GOROOT}" && \
    rm "${GO_TARBALL}"

ARG SYZKALLER=github.com/google/syzkaller
RUN go get -u -d "${SYZKALLER}/prog" && \
    make -C "${GOPATH}/src/${SYZKALLER}"

ARG VER=1
ARG ZIP_FILE=add-user-to-sudoers.zip
RUN wget -nv "https://github.com/starlab-io/add-user-to-sudoers/releases/download/${VER}/${ZIP_FILE}" && \
    unzip "${ZIP_FILE}" && \
    rm "${ZIP_FILE}" && \
    mkdir -p /usr/local/bin && \
    mv add_user_to_sudoers /usr/local/bin/ && \
    mv startup_script /usr/local/bin/ && \
    chmod 4755 /usr/local/bin/add_user_to_sudoers && \
    chmod +x /usr/local/bin/startup_script && \
                                              \
    # install defaults for bash
    { \
        echo "PS1='[\u@kernel-fuzz-docker \w]'" && \
        echo "if [ \$(id -u) -eq 0 ]; then PS1+='# '; else PS1+='$ '; fi" && \
        echo "alias su='su -l'"; \
    } | tee -a /etc/profile /etc/bash.bashrc /root/.bashrc >> /etc/bashrc && \
                                              \
    # Let regular users be able to use sudo
    echo $'auth       sufficient    pam_permit.so\n\
account    sufficient    pam_permit.so\n\
session    sufficient    pam_permit.so\n\
' > /etc/pam.d/sudo

FROM main AS bash
COPY bash_pub_key /tmp
ARG BASH_VER=5.0
RUN cd /tmp/ && \
    wget -nv http://ftp.gnu.org/gnu/bash/bash-${BASH_VER}.tar.gz && \
    wget -nv http://ftp.gnu.org/gnu/bash/bash-${BASH_VER}.tar.gz.sig && \
    gpg --import bash_pub_key && \
    gpg --verify bash-${BASH_VER}.tar.gz.sig && \
    tar xf bash-${BASH_VER}.tar.gz && \
    cd bash-${BASH_VER} && \
    ./configure \
        --prefix=/usr/local \
        --enable-alias \
        --enable-arith-for-command \
        --enable-array-variables \
        --enable-bang-history \
        --enable-brace-expansion \
        --enable-command-timing \
        --enable-cond-command \
        --enable-cond-regexp \
        --enable-coprocesses \
        --enable-debugger \
        --enable-dev-fd-stat-broken \
        --enable-directory-stack \
        --enable-disabled-builtins \
        --enable-dparen-arithmetic \
        --enable-extended-glob \
        --enable-help-builtin \
        --enable-history \
        --enable-job-control \
        --enable-multibyte \
        --enable-net-redirections \
        --enable-process-substitution \
        --enable-progcomp \
        --enable-prompt-string-decoding \
        --enable-readline \
        --enable-select \
        --enable-separate-helpfiles \
        --enable-mem-scramble && \
    make && \
    make install DESTDIR=/tmp/bash_install

FROM main
COPY --from=bash /tmp/bash_install /

ENTRYPOINT ["/usr/local/bin/startup_script"]
CMD ["/bin/bash", "-l"]
