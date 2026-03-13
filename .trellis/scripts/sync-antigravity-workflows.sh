#!/usr/bin/env bash
# Trellis Slash - 管理 Antigravity 的 Trellis 快捷指令
# 用法: bash .trellis/scripts/sync-antigravity-workflows.sh

WORKFLOW_SRC=".agent/workflows"
WORKFLOW_DST="$HOME/.gemini/antigravity/global_workflows"

# ─── 中文描述映射 ───
get_desc() {
  case "$1" in
    start)              echo "启动开发会话 - 初始化 Trellis 工作流" ;;
    finish-work)        echo "提交前检查清单" ;;
    record-session)     echo "记录工作会话进度" ;;
    brainstorm)         echo "需求发现与头脑风暴（复杂任务）" ;;
    break-loop)         echo "深度 Bug 分析 - 跳出调试循环" ;;
    before-backend-dev) echo "开发前阅读后端开发规范" ;;
    before-frontend-dev) echo "开发前阅读前端开发规范" ;;
    check-backend)      echo "检查代码是否符合后端开发规范" ;;
    check-frontend)     echo "检查代码是否符合前端开发规范" ;;
    check-cross-layer)  echo "跨层接口契约与数据流检查" ;;
    update-spec)        echo "更新代码规范 - 将可执行契约写入 spec" ;;
    integrate-skill)    echo "将新技能集成到项目规范中" ;;
    create-command)     echo "创建新的自定义工作流指令" ;;
    onboard)            echo "新成员入门引导" ;;
    *)                  echo "Trellis workflow: $1" ;;
  esac
}

# ─── 安装/同步 ───
do_install() {
  mkdir -p "$WORKFLOW_DST"
  added=0; updated=0; skipped=0

  for src_file in "$WORKFLOW_SRC"/*.md; do
    [ -f "$src_file" ] || continue
    name=$(basename "$src_file" .md)
    dst_file="$WORKFLOW_DST/trellis-${name}.md"
    desc=$(get_desc "$name")

    content="---
description: ${desc}
---

Read and execute the workflow defined in .agent/workflows/${name}.md
"
    if [ -f "$dst_file" ]; then
      existing=$(cat "$dst_file")
      if [ "$existing" = "$content" ]; then
        skipped=$((skipped + 1))
      else
        printf '%s' "$content" > "$dst_file"
        echo "  ✏️  更新: /trellis-${name}"
        updated=$((updated + 1))
      fi
    else
      printf '%s' "$content" > "$dst_file"
      echo "  ✅ 新增: /trellis-${name}"
      added=$((added + 1))
    fi
  done

  echo ""
  echo "同步完成！新增: ${added}, 更新: ${updated}, 无变化: ${skipped}"
}

# ─── 查看状态 ───
do_status() {
  echo ""
  echo "📂 源文件 ($WORKFLOW_SRC/):"
  src_count=0
  for f in "$WORKFLOW_SRC"/*.md; do
    [ -f "$f" ] || continue
    src_count=$((src_count + 1))
  done
  echo "  共 ${src_count} 个 workflow"

  echo ""
  echo "📂 已安装 ($WORKFLOW_DST/):"
  installed=0
  for f in "$WORKFLOW_DST"/trellis-*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .md | sed 's/^trellis-//')
    desc=$(get_desc "$name")
    echo "  /trellis-${name}  →  ${desc}"
    installed=$((installed + 1))
  done

  if [ "$installed" -eq 0 ]; then
    echo "  (空) 未安装任何 trellis workflow"
  else
    echo ""
    echo "  共 ${installed} 个已安装"
  fi
}

# ─── 清除 ───
do_clean() {
  count=$(find "$WORKFLOW_DST" -name "trellis-*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    printf "确认删除 ${count} 个 trellis workflow? [y/N] "
    read -r answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
      rm -f "$WORKFLOW_DST"/trellis-*.md
      echo "🗑️  已清除 ${count} 个文件"
    else
      echo "已取消"
    fi
  else
    echo "没有找到 trellis workflow 文件"
  fi
}

# ─── 交互菜单 ───
show_menu() {
  echo ""
  echo "╔══════════════════════════════════════╗"
  echo "║   Trellis Slash - Antigravity 管理   ║"
  echo "╚══════════════════════════════════════╝"
  echo ""
  echo "  1) 安装/更新  同步 workflow 到 Antigravity"
  echo "  2) 查看状态  列出已安装的 workflow"
  echo "  3) 清除全部  删除所有 trellis workflow"
  echo "  0) 退出"
  echo ""
  printf "请选择 [0-3]: "
  read -r choice

  case "$choice" in
    1) do_install ;;
    2) do_status ;;
    3) do_clean ;;
    0) echo "退出"; exit 0 ;;
    *) echo "无效选项" ;;
  esac
}

# ─── 入口 ───
# 支持直接传参: --install / --status / --clean
case "${1:-}" in
  --install|-i) do_install ;;
  --status|-s)  do_status ;;
  --clean|-c)   do_clean ;;
  *)            show_menu ;;
esac
