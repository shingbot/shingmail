# Shingmail — user/agent skill

用户/agent 侧的 Shingmail 邮箱技能：查设置、列邮件、读信、取验证码、发信、发件箱、删除、改密、退出。

- 服务面板：<https://mail.shingbot.com>
- 详细说明：[`shingmail-skill/SKILL.md`](shingmail-skill/SKILL.md)
- 本仓库是技能的**唯一源**；应用代码在私有仓库 `shingbot/shingmail`，不再包含本技能。

管理侧能力（建邮箱、发信开关、吊销 token、注册开关、审计）不在此仓库，由服务提供方使用私有管理工具。

## 要求

- Python 3.8+（只用标准库）
- 能访问 `https://mail.shingbot.com`

## 安装

```bash
# 1) 取仓库
git clone https://github.com/weshing/shingmail.git
cd shingmail

# 2) 安装到 agent skills 目录（默认 ~/.config/opencode/skills）
./install.sh

# 或指定目录
./install.sh ~/.claude/skills
```

手动安装：把 `shingmail-skill/` 整个目录放进 skills 目录，并确保 `scripts/shingmail` 可执行。

## 初始化

两种凭证二选一：

```bash
# A. agent token（推荐）：365 天，不保存密码
shingmail init --token '<agent-token>'

# B. 地址 + 密码（人类/CLI）：密码走隐藏输入
shingmail init --address alice@shingbot.com
```

凭证写到 `~/.config/shingmail/credentials.json`（0600）。程序入口是 `shingmail-skill/scripts/shingmail`，可加进 PATH 或用绝对路径。

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
| `shingmail passwd`（`password`） | 改密码（旧密码/旧 JWT 立即失效；仅地址+密码模式） |
| `shingmail logout [--forget]` | token 模式=服务端吊销；密码模式=只清本地 JWT |
| `shingmail --version` | 版本 |

输出统一为 JSON，便于 `jq` / agent 解析。

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
```

## 配置

| 项 | 值 |
|---|---|
| 凭证文件 | `~/.config/shingmail/credentials.json`（0600，可用 `SHINGMAIL_CONFIG` 覆盖） |
| `SHINGMAIL_BASE` | API 基址，默认 `https://mail.shingbot.com` |
| `SHINGMAIL_ADDRESS` / `SHINGMAIL_PASSWORD` | 地址 + 密码模式 |
| `SHINGMAIL_JWT` | agent token 模式 |
| `SHINGMAIL_SITE_PASSWORD` | 站点访问密码（当前未启用） |

## 安全

- 邮箱密码与 agent token 都是账户凭据：不要贴进对话、不要提交到仓库。
- 发信默认关闭；`settings.can_send=false` 时不要尝试 `send`。
- 长期授权用 agent token，不要给密码；`logout` 会吊销 token，agent 无法自行恢复。
- 密码模式下 `logout` 只是清本地 JWT，不是吊销；要真正停用请改密码或走管理侧重置/停用。