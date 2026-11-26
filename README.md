# shingmail — 用户 / agent 邮箱技能

用 `shingmail` 读写自己的 `@shingbot.com` 邮箱：查设置、列邮件、读信、取验证码或登录链接、发信、看已发送、删除、改密、退出。输出统一为 JSON，适合 `jq` 和 agent 直接解析。

[![CI](https://github.com/shingbot/shingmail/actions/workflows/ci.yml/badge.svg)](https://github.com/shingbot/shingmail/actions/workflows/ci.yml)

- 服务面板：<https://mail.shingbot.com>
- 技能说明：[`SKILL.md`](SKILL.md)

## 仓库定位

本仓库**只有用户/agent 侧技能**：`SKILL.md` + `scripts/shingmail` + 安装脚本。

服务端应用（Cloudflare Worker、邮件解析、管理侧能力）在私有仓库，不在这里；本仓库不包含也不依赖应用源码。

| 仓库 | 可见性 | 作用 |
|---|---|---|
| `shingbot/shingmail` | 公开 | 本技能（用户 / agent 侧） |
| `shingbot/shingmail-app` | 私有 | 服务端应用，需权限 |
| `weshing` | 母组织 | 其他产品（如 `shing-player`） |

管理侧能力（建邮箱、发信开关、吊销 token、注册开关、审计）由服务提供方用私有工具完成，不在本仓库。

## 要求

- Python 3.8+（只用标准库）
- 能访问 `https://mail.shingbot.com`

## 安装

### 方式 A：git clone（推荐）

```bash
git clone https://github.com/shingbot/shingmail.git
cd shingmail

# 默认安装到 ~/.config/opencode/skills/shingmail
./install.sh

# 或指定 skills 目录（会在目录下创建 shingmail/）
./install.sh ~/.claude/skills
```

也可以用 `OPENCODE_SKILLS_DIR` 指定默认目录。

### 方式 B：skills.sh CLI

```bash
npx skills add shingbot/shingmail
```

### 方式 C：手动

在 skills 目录下创建 `shingmail/`，把仓库里的 `SKILL.md` 和 `scripts/` 放进去，并确保 `scripts/shingmail` 可执行。

### 入口

安装后的入口是 `~/.config/opencode/skills/shingmail/scripts/shingmail`。可加进 PATH：

```bash
export PATH="$HOME/.config/opencode/skills/shingmail/scripts:$PATH"
```

下文示例都假设 `shingmail` 已在 PATH；否则请换成绝对路径。

> 从旧版升级：安装目录已由 `shingmail-skill` 改为 `shingmail`，`./install.sh` 会自动删除旧目录，避免同一技能出现两份。

## 初始化

两种凭证二选一：

```bash
# A. agent token（推荐给 agent）：365 天，不保存密码
shingmail init --token '<agent-token>'

# B. 地址 + 密码（人类 / CLI）：密码走隐藏输入
shingmail init --address alice@shingbot.com
```

凭证写到 `~/.config/shingmail/credentials.json`（0600）。token 模式不会存密码；地址 + 密码模式会用密码换 7 天 JWT，并在过期或 401 时自动重登。

## 命令

| 命令 | 说明 |
|---|---|
| `shingmail settings`（`whoami`） | 当前邮箱、发信余额、`can_send` |
| `shingmail list [--limit 20] [--offset 0]` | 收件箱（服务端已解析） |
| `shingmail read <id>` | 读一封邮件（含正文与附件元数据） |
| `shingmail code` | 取最新一封的验证码 / 第一个链接 |
| `shingmail send --to x@y.com --subject 主题 --body 内容 [--html] [--from-name 名字]` | 发信（需 `can_send=true`） |
| `shingmail sendbox [--limit 20]` | 已发送 |
| `shingmail delete <id>` | 删除收件箱邮件 |
| `shingmail passwd`（`password`） | 改密码（旧密码 / 旧 JWT 立即失效；仅地址 + 密码模式） |
| `shingmail logout [--forget]` | token 模式=服务端吊销；密码模式=只清本地 JWT |
| `shingmail --version` | 版本 |

## 示例

```bash
shingmail list | jq '.results[0] | {id, subject, sender, created_at}'
shingmail code | jq -r '.code // .link'

# 等验证码
for i in {1..20}; do
  out=$(shingmail code)
  echo "$out" | jq -e '.code' >/dev/null && { echo "$out"; break; }
  sleep 3
done

# 发信
shingmail send --to someone@example.com --subject test --body hello
```

## 配置

| 项 | 值 |
|---|---|
| 凭证文件 | `~/.config/shingmail/credentials.json`（0600，可用 `SHINGMAIL_CONFIG` 覆盖） |
| `SHINGMAIL_BASE` | API 基址，默认 `https://mail.shingbot.com` |
| `SHINGMAIL_ADDRESS` / `SHINGMAIL_PASSWORD` | 地址 + 密码模式 |
| `SHINGMAIL_JWT` | agent token 模式 |
| `SHINGMAIL_SITE_PASSWORD` | 站点访问密码（当前未启用） |

## 目录结构

```text
.
├── SKILL.md              # 技能定义（agent 读取）
├── scripts/shingmail     # 命令行入口（Python 3，标准库）
├── install.sh            # 安装到 skills 目录
├── README.md
└── .github/workflows/    # CI：语法、版本、帮助、可执行位、安装冒烟
```

## 常见问题

| 现象 | 原因 / 处理 |
|---|---|
| `401 InvalidAddressCredentialMsg` | JWT 过期/不对；密码模式会自动重登；仍失败检查地址/密码 |
| `423 Too many failed login attempts` | 登录锁定（同 IP+邮箱 10 次 / 跨 IP 50 次，15 分钟）；等 15 分钟 |
| `429 Rate limit exceeded` | IP+path 20 次/分钟；按 3s→10s 退避 |
| `Sending is disabled for this mailbox` | `can_send=false`；联系管理员开通，不要重试 |
| `send_balance` 为 0 | 余额用尽；联系管理员 |
| `CustomAuthPasswordMsg` | 站点又开启访问密码；补 `SHINGMAIL_SITE_PASSWORD` |
| `404 on parsed_mail` | 旧部署；改用 `/api/mails` + 本地解析 |

## 退出与吊销

| 场景 | 命令 | 效果 |
|---|---|---|
| agent token 停用 | `shingmail logout` | 服务端 `token_version+1`，token 立即失效；agent 无法自行恢复 |
| 密码模式退出 | `shingmail logout` | 只清本地 JWT；密码还在就能再登录，**不是吊销** |
| 彻底停用 | `shingmail passwd` 或管理侧 `disable` | 旧密码 / 旧 JWT 一起失效 |

## 版本与发布

- 当前版本：**1.2.0**（`shingmail --version`）。
- 推送后 GitHub Actions 会跑语法检查、`--version` / `--help`、可执行位、`bash -n install.sh`，并做一次安装冒烟。
- 修改后提交到 `shingbot/shingmail`；不要再把技能复制回应用仓库。

## 安全

- 邮箱密码与 agent token 都是账户凭据：不要贴进对话、不要提交到仓库。
- 发信默认关闭；`settings.can_send=false` 时不要尝试 `send`。
- 长期授权用 agent token，不要给密码；`logout` 会吊销 token，agent 无法自行恢复。
- 密码模式下 `logout` 只是清本地 JWT，不是吊销；要真正停用请改密码或走管理侧重置 / 停用。

## License

Apache-2.0，见 [`LICENSE`](LICENSE)。