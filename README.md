# Shingmail — user/agent skill (public)

`shingmail-skill` 是用户/agent 侧的 Shingmail 邮箱技能：查设置、列邮件、读信、取验证码、发信、发件箱、删除、改密、退出。

管理侧能力（建邮箱、发信开关、吊销 token、注册开关、审计）不在此仓库，由服务提供方使用私有管理工具。

## 安装

把 `shingmail-skill/` 放进 agent 的 skills 目录，并确保 `shingmail-skill/scripts/shingmail` 可执行。

```bash
chmod +x shingmail-skill/scripts/shingmail
shingmail init --token '<agent-token>'   # 推荐：agent token（不保留密码）
# 或
shingmail init --address alice@shingbot.com
```

## 命令

| 命令 | 说明 |
|---|---|
| `shingmail settings` | 查看当前邮箱设置（发信权限等） |
| `shingmail list` | 列出收件箱 |
| `shingmail read <id>` | 读信 |
| `shingmail code` | 取最新验证码 |
| `shingmail send` | 发信（需要发信权限） |
| `shingmail sendbox` | 查看发件箱 |
| `shingmail delete <id>` | 删除邮件 |
| `shingmail passwd` | 修改密码（会让旧 token 失效） |
| `shingmail logout` | 退出（仅密码模式） |

服务面板：<https://mail.shingbot.com>
