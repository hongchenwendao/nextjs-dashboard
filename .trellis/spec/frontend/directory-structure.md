# 目录结构

> 本项目前端代码的组织方式。

---

## 概述

这是一个 **Next.js 15 App Router** 项目。所有代码位于 `app/` 目录下，遵循 App Router 约定：文件系统决定路由结构。

核心组织原则：
- **路由段** 在 `app/` 中定义 URL 结构
- **UI 组件** 按功能域分组（而非按组件类型）
- **共享工具** 位于 `app/lib/`
- **服务端数据获取** 在 `app/lib/data.ts` 中

---

## 目录布局

```
app/
├── lib/                        # 共享工具和数据层
│   ├── definitions.ts          # TypeScript 类型定义（手动定义，无 ORM）
│   ├── data.ts                 # 数据库查询（postgres SQL，无 ORM）
│   ├── utils.ts                # 纯工具函数（formatCurrency 等）
│   └── placeholder-data.ts     # 开发环境种子数据
│
├── ui/                         # UI 组件（按功能分组）
│   ├── dashboard/              # 仪表板专用组件
│   │   ├── sidenav.tsx         # 侧边导航
│   │   ├── nav-links.tsx       # 导航链接
│   │   ├── cards.tsx           # 卡片组件
│   │   ├── latest-invoices.tsx # 最新发票
│   │   └── revenue-chart.tsx   # 收入图表
│   ├── invoices/               # 发票相关组件
│   │   ├── table.tsx           # 发票表格
│   │   ├── create-form.tsx     # 创建表单
│   │   ├── edit-form.tsx       # 编辑表单
│   │   ├── buttons.tsx         # 操作按钮
│   │   ├── status.tsx          # 状态标签
│   │   ├── breadcrumbs.tsx     # 面包屑
│   │   └── pagination.tsx      # 分页组件
│   ├── customers/              # 客户相关组件
│   │   └── table.tsx           # 客户表格
│   ├── button.tsx              # 共享 UI 组件
│   ├── login-form.tsx          # 登录表单
│   ├── search.tsx              # 搜索组件
│   ├── skeletons.tsx           # 骨架屏
│   ├── acme-logo.tsx           # Logo 组件
│   └── fonts.tsx               # 字体配置
│
├── dashboard/                  # 仪表板路由（布局 + 页面）
│   ├── layout.tsx              # 仪表板布局包裹器
│   ├── page.tsx                # 仪表板首页
│   ├── customers/page.tsx      # 客户页面
│   └── invoices/page.tsx       # 发票页面
│
├── layout.tsx                  # 根布局（字体、HTML 结构）
├── page.tsx                    # 落地页
├── seed/route.ts               # 数据库种子数据端点
└── query/route.ts              # 自定义查询模板
```

---

## 模块组织

### 添加新功能

添加新功能（如"产品"）时：

1. **创建路由**: `app/dashboard/products/page.tsx`
2. **创建 UI 组件**: `app/ui/products/` 目录
   - `table.tsx` - 数据表格
   - `buttons.tsx` - 操作按钮
   - `create-form.tsx` - 创建表单
   - 等等
3. **添加类型** 到 `app/lib/definitions.ts`
4. **添加数据函数** 到 `app/lib/data.ts`

### 组件组织规则

- **按功能分组，而非按类型** - 组件按域分组（invoices/、customers/）
- **共享组件** 直接放在 `app/ui/` 中（button.tsx、search.tsx）
- **一个文件一个组件** - 保持文件职责单一

---

## 命名约定

### 文件命名

| 类型 | 约定 | 示例 |
|------|------|------|
| 组件 | `kebab-case.tsx` | `sidenav.tsx`、`create-form.tsx`、`latest-invoices.tsx` |
| 工具函数 | `kebab-case.ts` | `utils.ts`、`data.ts` |
| 路由 | `page.tsx`、`layout.tsx` | 始终使用 Next.js 约定 |
| 类型 | `camelCase.ts` | `definitions.ts`（所有类型在一个文件中） |

### 导出约定

- **默认导出** 用于页面/布局组件（Next.js 要求）
- **命名导出** 用于可复用组件和工具函数

```typescript
// 页面/路由 - 默认导出
export default function Page() { ... }

// 可复用组件 - 命名导出
export function Button() { ... }
export { CreateInvoice, DeleteInvoice } from './buttons';
```

---

## 路径别名

项目使用 `tsconfig.json` 中配置的 `@/*` 路径别名：

```typescript
import { Button } from '@/app/ui/button';
import { formatCurrency } from '@/app/lib/utils';
import { Invoice } from '@/app/lib/definitions';
```

**跨文件引用时始终使用 `@/` 导入** - 避免使用相对路径如 `../../../lib/utils`。

---

## 示例

参考组织良好的模块：

- **仪表板导航**: [app/ui/dashboard/sidenav.tsx](../../app/ui/dashboard/sidenav.tsx)
- **发票功能**: [app/ui/invoices/](../../app/ui/invoices/) - 完整的功能模块
- **数据层**: [app/lib/data.ts](../../app/lib/data.ts) - 所有数据库查询

---

## 特殊文件

| 文件 | 用途 |
|------|------|
| `app/layout.tsx` | 根布局 - 定义 HTML 结构、字体 |
| `app/dashboard/layout.tsx` | 仪表板布局 - 用侧边栏包裹所有仪表板页面 |
| `app/lib/definitions.ts` | 集中的类型定义 - 所有领域类型在此 |
| `app/lib/data.ts` | 服务端数据获取 - 带有 postgres 的异步函数 |
| `app/lib/utils.ts` | 纯工具函数 - 无副作用 |

---

## 应避免的反模式

- **不要** 在 `app/` 外创建 `components/` 或 `lib/` - 所有内容保持在 `app/` 下
- **不要** 按组件类型组织（如 `components/tables/`、`components/forms/`） - 按功能组织
- **不要** 将类型分散到多个文件 - 保持所有领域类型在 `definitions.ts` 中
- **不要** 使用 ORM 生成的类型 - 我们手动定义类型以保持清晰
