# webtop(Selkies,XFCE on Ubuntu)+ 开发环境 + JetBrains IDE + sshd
FROM lscr.io/linuxserver/webtop:ubuntu-xfce

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=24
ARG GO_VERSION=latest
# 改这个数字可让下面的 IDE 层重新下载最新版(否则 docker 缓存会一直用旧的)
ARG JB_REFRESH=1

USER root

# ---- 基础工具 / 编译链 / Python / JDK / SSH
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg git git-lfs patch rsync ripgrep fd-find tmux jq pandoc \
      unzip zip xz-utils less vim nano htop tree sqlite3 \
      build-essential cmake ninja-build pkg-config gdb clang \
      python3 python3-venv python3-pip python3-dev python3-pytest pipx \
      openjdk-21-jdk maven \
      openssh-server openssh-client sudo iproute2 iputils-ping dnsutils netcat-openbsd nmap \
 && rm -rf /var/lib/apt/lists/*

# ---- Docker CLI + compose + buildx(只有客户端)
RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list \
 && apt-get update && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin docker-buildx-plugin \
 && rm -rf /var/lib/apt/lists/*

# ---- Node
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g yarn pnpm typescript ts-node nodemon \
 && rm -rf /var/lib/apt/lists/* /root/.npm

# ---- Go + 常用工具(装到 /usr/local/bin)
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; v="${GO_VERSION}"; \
    if [ "$v" = latest ]; then v="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1)"; fi; \
    case "$v" in go*) ;; *) v="go$v";; esac; \
    curl -fsSL "https://go.dev/dl/${v}.linux-${arch}.tar.gz" | tar -C /usr/local -xz; \
    export PATH="$PATH:/usr/local/go/bin" GOPATH=/tmp/gopath GOBIN=/usr/local/bin GOCACHE=/tmp/gocache; \
    go install golang.org/x/tools/gopls@latest; \
    go install honnef.co/go/tools/cmd/staticcheck@latest; \
    go install github.com/go-delve/delve/cmd/dlv@latest; \
    go clean -modcache; rm -rf /tmp/gopath /tmp/gocache

# ---- Rust(工具链放 /opt,cargo 缓存运行时落到 /config)
ENV RUSTUP_HOME=/opt/rustup
RUN curl -fsSL https://sh.rustup.rs | CARGO_HOME=/opt/cargo sh -s -- -y --profile minimal \
      -c clippy -c rustfmt -c rust-src --no-modify-path \
 && chmod -R a+rX /opt/rustup /opt/cargo

# ---- 环境变量(桌面 / ssh 都要)
ENV GOPATH=/config/go \
    CARGO_HOME=/config/.cargo
ENV PATH="/usr/local/go/bin:/opt/cargo/bin:/config/go/bin:${PATH}"
RUN { \
      echo "PATH=\"/usr/local/go/bin:/opt/cargo/bin:/config/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\""; \
      echo "GOPATH=\"/config/go\""; echo "CARGO_HOME=\"/config/.cargo\""; echo "RUSTUP_HOME=\"/opt/rustup\""; \
    } > /etc/environment

# ---- JetBrains IDE(每个一层,失败可单独重试)
COPY --chmod=0755 install-jb /usr/local/bin/install-jb
ARG JB_REFRESH
RUN install-jb IIU idea       idea
RUN install-jb GO  goland     goland
RUN install-jb PCP pycharm    pycharm
RUN install-jb RR  rustrover  rustrover
RUN install-jb CL  clion      clion

# ---- 用户 abc(webtop 桌面用户)可 ssh 登录、免密 sudo
RUN usermod -s /bin/bash -p '*' abc \
 && echo 'abc ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/99-dev-nopasswd && chmod 440 /etc/sudoers.d/99-dev-nopasswd \
 && sed -i 's/^\(session\s\+required\s\+pam_loginuid.so\)/session optional pam_loginuid.so/' /etc/pam.d/sshd \
 && mkdir -p /run/sshd /etc/ssh/hostkeys /etc/ssh/authorized_keys

COPY sshd_dev.conf /etc/ssh/sshd_config.d/10-dev.conf
COPY --chmod=0755 svc-sshd /custom-services.d/sshd
COPY --chmod=0755 init-docker-sock /custom-cont-init.d/20-docker-sock

# ---- 默认配置(放最后一层:改这些只重跑本层,IDE 层走缓存)
# 构建时由 GitHub 的 secret/variable 传入;运行时用 -e / .env 可覆盖
ARG WEB_PASSWORD=changeme
ARG SSH_PUBLIC_KEY=
ENV TZ=UTC \
    PUID=1000 \
    PGID=1000 \
    CUSTOM_USER=dev \
    TITLE=ubuntu-dev-webtop \
    PASSWORD=${WEB_PASSWORD} \
    SSH_PUBLIC_KEY=${SSH_PUBLIC_KEY}

EXPOSE 3000 3001 22
