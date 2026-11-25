# Shingmail skill (public)

`shingmail-skill` — 用户/agent 侧邮箱操作技能（只收/读/取码/发信，取决于邮箱权限）。

## 安装

把 `shingmail-skill/` 放进你的 skills 目录，确保 `scripts/shingmail` 可执行（或加入 PATH）。

```bash
shingmail init --token '...'     # 推荐：agent token（不存密码）
# 或
shingmail init --address alice@shingbot.com
```

## 命令

`settings / list / read / code / send / sendbox / delete / passwd / logout`

管理侧（建邮箱、发信开关、吊销 token）不在本仓库，由服务提供方使用私有管理工具。
