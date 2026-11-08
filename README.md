# ubuntu-dev-webtop

linuxserver/webtop(XFCE 浏览器桌面)+ SSH + Go / Rust / Node / Python / JDK 21 / C++ 工具链 + IntelliJ IDEA / GoLand / PyCharm / RustRover / CLion 的开发镜像。

镜像:Docker Hub `<你的用户名>/ubuntu-dev-webtop`(push main 自动构建,每月 1 号重建刷新 IDE)。
镜像含 JetBrains IDE,**Docker Hub 仓库保持 Private**。

## 镜像约定
- 桌面用户 `abc`,home `/config`;web 桌面 3001(https)/3000;SSH 22(仅公钥,用户 `abc`)。
- 默认值在构建时写进镜像,运行时可用 `-e` 或 `.env` 覆盖:
  `TZ`(UTC)、`PUID`/`PGID`(1000)、`CUSTOM_USER`(dev)、`PASSWORD`、`SSH_PUBLIC_KEY`(多个用 `\n` 分隔)。
- 新增登录用户:设 `DEV_USER`(可选 `DEV_PASSWORD`、`DEV_SUDO`、`DEV_UID`/`DEV_GID`/`DEV_HOME`,见 `.env.example`)。默认与 `abc` 同 uid、共用 home 和公钥,SSH 可用 `DEV_USER` 登录。
- 也可把公钥放进 `/config/.ssh/authorized_keys`。
- 挂 `/etc/ssh/hostkeys` 可持久化 host key;挂 `/var/run/docker.sock` 时 `abc` 自动加入对应组。
- 其余(网络、端口、挂载)自行决定,见 `compose.yml` 示例。

## GitHub 构建配置(在网页上设,改完 Run workflow 即可,IDE 层走缓存不重下)
- Secrets:`DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN`、`WEB_PASSWORD`(桌面默认密码,可选)
- Variables:`SSH_PUBLIC_KEY`(默认公钥,可选)

## 快速使用
```
docker compose pull && docker compose up -d      # 或 docker compose build
```
- 桌面 `https://<host>:3101`;SSH `ssh -p 2200 abc@<host>`
- 本地构建默认密码为 `changeme`,可 `docker compose build --build-arg WEB_PASSWORD=xxx --build-arg SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"`
