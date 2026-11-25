---
name: shingmail-skill
description: 用 shingmail（https://mail.shingbot.com）读写自己的 @shingbot.com 邮箱：列出收件箱、读信、取验证码或登录链接、发信、看已发送。凭证是「邮箱地址 + 邮箱密码」（或 SHINGMAIL_JWT）；首次 `shingmail init` 写入 ~/.config/shingmail/credentials.json（0600）。当用户要查某个网站的验证码、读一封邮件、用自己的 @shingbot.com 邮箱发信，或提到 shingmail / shingbot 邮箱 / 临时邮箱时使用。
version: 1.1.0
---

# shingmail — 用户侧收发邮件

一个邮箱 = 一个地址（+ 密码或 agent token）。本技能只操作**自己的**邮箱。

服务端：Cloudflare Worker `shingmail`，API 基址 `https://mail.shingbot.com`，邮件域 `@shingbot.com`。

## 一、准备

安装：从 <https://github.com/weshing/shingmail> 取仓库，运行 `./install.sh [skills 目录]`（默认 `~/.config/opencode/skills`）；或把 `shingmail-skill/` 手动放进 skills 目录。命令入口是 `scripts/shingmail`（加进 PATH，或用绝对路径调用）。

你会拿到两种凭证之一：

- **Agent token（推荐给 agent）**：一次性拿到一个 JWT，有效期 365 天；不保存密码。
- **地址 + 密码（人工 / CLI）**：用密码换 7 天 JWT。

### 方式 A：agent token（推荐）

```bash
shingmail init --token 'eyJ...'
```

token 只存到 `~/.config/shingmail/credentials.json`（0600），不会存密码；agent token **不能改密码**。token 过期或被吊销后，需要重新获取新的 token。

### 方式 B：地址 + 密码

```bash
shingmail init --address alice@shingbot.com
```

密码走隐藏输入，不会进 shell history。

### 环境变量（CI / 自动化）

```bash
export SHINGMAIL_JWT='...'               # agent token
# 或
export SHINGMAIL_ADDRESS=alice@shingbot.com
export SHINGMAIL_PASSWORD='...'          # 不建议写进脚本
```

凭证文件：`~/.config/shingmail/credentials.json`，权限 600（可用 `SHINGMAIL_CONFIG` 指定其他路径）。里面会缓存 JWT 及其过期时间；密码模式下 JWT 快过期或 401 时自动用密码重登；token 模式下不会自动续期。

> 站点访问密码当前**已关闭**，一般不需要 `SHINGMAIL_SITE_PASSWORD`；只有以后重新开启时才有用。

## 二、命令

| 命令 | 作用 |
|---|---|
| `shingmail settings`（或 `whoami`） | 当前邮箱、发信余额 |
| `shingmail list [--limit 20] [--offset 0]` | 收件箱（服务端已解析 subject/text/html） |
| `shingmail read <id>` | 读一封邮件（含附件元数据） |
| `shingmail code` | 取最新一封里的 6 位验证码 / 第一个链接 |
| `shingmail send --to x@y.com --subject 主题 --body 内容 [--html] [--from-name 名字]` | 发信 |
| `shingmail sendbox [--limit 20]` | 已发送 |
| `shingmail delete <id>` | 删除收件箱邮件 |
| `shingmail passwd`（或 `password`） | 仅地址+密码模式：改密码（当前密码校验 + 新密码；旧密码/旧 JWT 立即失效） |
| `shingmail logout [--forget]` | token 模式：服务端吊销 token（agent 无密码，无法自行恢复）；密码模式：只清当前 JWT，密码还在就还能再登录；`--forget` 连本地密码一起删 |

输出统一是 JSON，方便 agent 直接解析：

```bash
shingmail list | jq '.results[0] | {id, subject, sender, created_at}'
shingmail code | jq -r '.code // .link'
shingmail send --to someone@example.com --subject test --body hello
```

## 三、常见用法

**等验证码**：先发触发邮件，再轮询：

```bash
for i in {1..20}; do
  out=$(shingmail code)
  echo "$out" | jq -e '.code' >/dev/null && { echo "$out"; break; }
  sleep 3
done
```

**读完整正文**：`shingmail read <id> | jq -r '.text'`

**发信**：仅当 `settings.can_send=true` 时可用。若 `send` 返回 `Sending is disabled for this mailbox`，不要重试，告知用户「该邮箱当前不能发信」即可。可用时默认有 10 封余额。

## 四、错误对照

| 现象 | 原因 / 处理 |
|---|---|
| `401 InvalidAddressCredentialMsg` | JWT 过期或不对；脚本会自动用密码重登；仍失败就检查地址/密码 |
| `CustomAuthPasswordMsg` | 站点又开启了访问密码；补 `SHINGMAIL_SITE_PASSWORD` |
| `send_balance` 为 0 / 发信失败 | 余额用完、发信功能不可用或服务端限额；停止重试并告知用户 |
| `429` | 限流；按 3s→10s 退避 |
| 404 on `parsed_mail` | 旧部署；改用 `/api/mails` + 本地解析（本技能默认走 parsed） |

## 五、安全

- 邮箱密码 / agent token 都是账户凭据，不要贴进对话、不要提交到仓库；只放 600 文件或密码管理器。
- **agent token 模式**：`shingmail logout` 会让服务端 `token_version + 1`，token 立即失效；agent 没有密码，**无法自行恢复**，需要重新授权（签发新 token）。这是给 agent 用的推荐模式。
- **地址+密码模式**：`logout` 只清当前 JWT；agent 只要还存着密码就能重新登录，**它不是吊销**。要真正停掉，必须用 `shingmail passwd` 改密码（旧密码/旧 JWT 一起失效），或走重置/停用流程。
- `shingmail logout --forget` 会连本地密码一起删，下次必须重新输入；但如果密码在别处还有副本，服务端仍然认。
- 把密码直接交给 agent 时，agent 也能改密码；所以长期授权请用 agent token，不要给密码。
- 发信默认关闭；`settings.can_send=false` 时不要尝试 `send`。
- 只操作自己的地址；不要尝试读别人的邮箱。