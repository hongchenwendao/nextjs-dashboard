# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 开发命令

```bash
# 启动开发服务器（使用 Turbopack）
pnpm dev

# 生产环境构建
pnpm build

# 启动生产服务器
pnpm start
```

注意：本项目使用 **pnpm** 作为包管理器（见 package.json 中的 `onlyBuiltDependencies`）。

## 架构概览

这是一个使用 **App Router** 模式的 Next.js 15 仪表板应用，来自 Next.js Learn Course 的入门模板。

### 技术栈

- **Next.js 15** + App Router + TypeScript
- **PostgreSQL** 通过 `postgres` 包（**不是** Prisma - 使用原生 SQL 查询）
- **Tailwind CSS** + `@tailwindcss/forms` 插件
- **next-auth** v5 beta 用于身份认证
- **Zod** 用于 schema 验证
- **bcrypt** 用于密码哈希
- **Heroicons** 图标库

### 项目结构

```
app/
├── lib/
│   ├── definitions.ts      # TypeScript 类型定义（手动定义，无 ORM）
│   ├── data.ts             # 数据获取函数（postgres SQL 查询）
│   ├── utils.ts            # 工具函数（formatCurrency、formatDate 等）
│   └── placeholder-data.ts # 数据库种子数据
├── ui/
│   ├── dashboard/          # 仪表板相关组件
│   ├── invoices/           # 发票相关组件
│   ├── customers/          # 客户相关组件
│   └── *.tsx               # 共享 UI 组件（Button、LoginForm 等）
├── seed/route.ts           # 数据库种子数据端点
├── query/route.ts          # 自定义查询模板路由
├── layout.tsx              # 根布局
└── page.tsx                # 首页
```

### 数据库访问模式

**不使用 ORM**。所有数据库查询都使用 `postgres` 包编写原生 SQL：

```typescript
import postgres from 'postgres';

const sql = postgres(process.env.POSTGRES_URL!, { ssl: 'require' });

// 示例查询
const data = await sql<Invoice[]>`SELECT * FROM invoices`;
```

`app/lib/data.ts` 中的数据获取函数遵循以下模式：
1. Try-catch 错误处理
2. Tagged template literal SQL 语法
3. 泛型类型参数用于 TypeScript 类型推断
4. 失败时抛出描述性错误

### 类型定义

所有类型在 `app/lib/definitions.ts` 中手动定义（无 ORM 代码生成）：
- `User`, `Customer`, `Invoice`, `Revenue`
- `LatestInvoice`, `LatestInvoiceRaw`
- `InvoicesTable`, `CustomersTableType`, `FormattedCustomersTable`
- `CustomerField`, `InvoiceForm`

**金额以"分"为单位存储为整数**（例如 $50.00 = 5000），使用 `formatCurrency()` 转换。

### 组件组织方式

UI 组件按功能域组织，而非按组件类型：
- `app/ui/dashboard/` - 仪表板专用组件
- `app/ui/invoices/` - 发票相关组件
- `app/ui/customers/` - 客户相关组件

### 路径别名

项目使用 `tsconfig.json` 中配置的 `@/*` 路径别名：
```typescript
import { Button } from '@/app/ui/button';
import { formatCurrency } from '@/app/lib/utils';
```

### 环境变量

必需的环境变量（参见 `.env.example`）：
- `POSTGRES_URL` - PostgreSQL 连接字符串（Vercel Postgres）
- `AUTH_SECRET` - 使用 `openssl rand -base64 32` 生成
- `AUTH_URL` - 认证回调 URL

### 数据库表结构

表：`users`, `customers`, `invoices`, `revenue`

访问 `GET /app/seed` 可初始化数据库（创建表并插入种子数据）。
