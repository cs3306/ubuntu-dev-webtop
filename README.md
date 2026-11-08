# ubuntu-dev-webtop

linuxserver/webtop(XFCE 浏览器桌面)+ SSH + Go / Rust / Node / Python / JDK 21 / C++ 工具链 + IntelliJ IDEA / GoLand / PyCharm / RustRover / CLion 的开发镜像。

镜像:Docker Hub `<你的用户名>/ubuntu-dev-webtop`(push main 自动构建;**不再定时重建**,版本不会自己变)。
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
- Variables(全部可选):`SSH_PUBLIC_KEY`(默认公钥)、`WITH_OFFICE`(设 0 跳过 LibreOffice/PDF/OCR)、`TEXLIVE_PKG`(默认 `texlive-full ...`,想小一点可设 `texlive-latex-extra texlive-lang-chinese latexmk`)、`APT_EXTRA` / `PIP_EXTRA`(额外系统包 / Python 包,空格分隔)、`JB_PLUGINS_EXTRA`(额外 JetBrains 插件 ID,装进所有 IDE)

## 快速使用
```
docker compose pull && docker compose up -d      # 或 docker compose build
```
- 桌面 `https://<host>:3101`;SSH `ssh -p 2200 abc@<host>`
- 本地构建默认密码为 `changeme`,可 `docker compose build --build-arg WEB_PASSWORD=xxx --build-arg SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"`

## 内置工具
- LaTeX:TeX Live 完整版 + latexmk / biber / chktex / TeXstudio(中文用 xelatex / lualatex + `fonts-noto-cjk`)。
- 办公:LibreOffice(Writer/Calc/Impress/Draw,可 `soffice --headless --convert-to pdf x.docx`)、evince、poppler / qpdf / pdftk / ghostscript、OCR(`ocrmypdf -l chi_sim+eng`)、Python 的 openpyxl / python-docx / python-pptx / pypdf / pdfplumber / reportlab / pandas / matplotlib。
- JetBrains 插件(各 IDE 内置目录,构建时装入):GitToolBox、Key Promoter X、.env files support、SonarLint、Rainbow Brackets、TeXiFy(LaTeX);IDEA 另有 Go / Python / Rust,PyCharm 有 Go,CLion 有 Rust。Docker、Markdown 为 IDE 自带。

## 扩展
- 构建期:见上面的 GitHub Variables;本地构建用 `--build-arg APT_EXTRA="..." --build-arg PIP_EXTRA="..." --build-arg JB_PLUGINS_EXTRA="..."`。
- 运行期(`.env`):`APT_INSTALL` / `PIP_INSTALL` / `NPM_INSTALL`(空格分隔,每次启动安装)。
- 持久脚本:把 `*.sh` 放进 `/config/init.d/`(在卷里,重建不丢,root 启动时执行),例如装插件:`install-jb-plugins /opt/goland <插件ID>`。
- 也可自行向 `/custom-cont-init.d/`(单个文件挂载,勿挂整个目录以免覆盖内置脚本)和 `/custom-services.d/` 添加启动脚本。

## 版本与更新(默认不自动更新)
- 镜像 tag:`latest` 和 `r<构建序号>`;想锁定就在 compose 里用 `r12` 这类 tag,不用 `latest`。
- 缓存:没改相关层就复用,IDE / Go / Node 版本不变。
- 固定 IDE 版本:GitHub Variables 设 `JB_IDEA_VERSION` / `JB_GOLAND_VERSION` / `JB_PYCHARM_VERSION` / `JB_RUSTROVER_VERSION` / `JB_CLION_VERSION`(如 `2025.2.4`,留空 = latest);本地用 `--build-arg JB_IDEA_VERSION=2025.2.4`。Go / Node 用 `GO_VERSION` / `NODE_MAJOR` 构建参数。
- 通过构建拿最新:Actions → Run workflow 勾选 `refresh_ide`;或把 Dockerfile 里 `ARG JB_REFRESH=1` 数字加 1 再 push。
- 容器内手动更新(重建容器后丢失,长期用请固定到构建参数):
  `sudo install-jb GO goland goland [版本]`,插件随后 `sudo install-jb-plugins /opt/goland <插件ID...>`。
