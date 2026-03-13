# 质量指南

> 前端开发的代码质量标准。

---

## 概述

本项目遵循 Next.js 和 React 的最佳实践。代码质量通过以下方式保证：

- **TypeScript 严格模式** - 编译时类型检查
- **ESLint** - 代码 lint（通过 Next.js 内置）
- **代码审查** - 人工审查
- **测试** - 手动测试（当前无自动化测试）

---

## 禁止模式

| 模式 | 为什么禁止 | 替代方案 |
|------|------------|----------|
| `any` 类型 | 失去类型安全 | 使用具体类型或 `unknown` |
| `@ts-ignore` | 绕过类型检查 | 修复底层类型问题 |
| `@ts-expect-error` | 暂时绕过检查 | 仅在极少数情况下使用 |
| 内联 `style` 对象 | 难以维护 | 使用 Tailwind 类 |
| `localStorage` 直接访问 | 需要服务端渲染考虑 | 使用 useEffect 包裹 |
| `alert()` | 用户体验差 | 使用 toast/模态框 |
| 硬编码字符串 | 国际化困难 | 提取为常量 |
| 巨大组件 (>300 行) | 难以理解/维护 | 拆分为小组件 |
| 嵌套三元运算符 | 难以阅读 | 使用条件渲染或提取函数 |
| 在循环中定义组件 | 性能/状态问题 | 提取到循环外 |

### 禁止的导入模式

```typescript
// 错误：从 Next.js 外部导入
import { useRouter } from 'next/router'; // 旧的 Pages Router
// 正确
import { useRouter } from 'next/navigation'; // App Router

// 错误：从错误位置导入组件
import { Button } from '@/app/ui/components/button';
// 正确
import { Button } from '@/app/ui/button';
```

---

## 必需模式

### 组件结构

```typescript
// 1. 外部依赖
import Link from 'next/link';
import { PencilIcon } from '@heroicons/react/24/outline';

// 2. 内部依赖
import { Button } from '@/app/ui/button';
import { formatCurrency } from '@/app/lib/utils';

// 3. 类型定义
interface TableProps {
  // ...
}

// 4. 组件定义
export default function Table({ ... }: TableProps) {
  // ...
}
```

### 命名导出

```typescript
// 可复用组件使用命名导出
export function Button() { ... }
export { CreateInvoice, DeleteInvoice } from './buttons';

// 页面/布局使用默认导出
export default function Page() { ... }
```

### 路径别名

```typescript
// 始终使用 @/ 别名
import { Button } from '@/app/ui/button';  // 好的做法
import { Button } from '../../../ui/button'; // 错误的做法
```

### 错误处理

```typescript
// 数据库操作使用 try-catch
export async function fetchRevenue() {
  try {
    const data = await sql<Revenue[]>`SELECT * FROM revenue`;
    return data;
  } catch (error) {
    console.error('Database Error:', error);
    throw new Error('Failed to fetch revenue data.');
  }
}
```

---

## 测试要求

### 当前状态

本项目目前**没有自动化测试**。测试通过以下方式进行：

- **手动测试** - 开发时在浏览器中验证
- **构建检查** - `pnpm build` 确保无编译错误

### 未来测试计划

如果添加测试，优先级如下：

1. **E2E 测试** - 使用 Playwright 测试关键用户流程
2. **组件测试** - 使用 Testing Library 测试复杂组件
3. **单元测试** - 工具函数和数据获取逻辑

### 测试覆盖目标（未来）

- 关键用户流程：100%（登录、创建发票）
- 复杂组件：>80%
- 工具函数：>90%

---

## Linting

### ESLint

Next.js 内置 ESLint 配置。运行：

```bash
pnpm build
```

构建过程会自动运行 lint 检查。失败将阻止部署。

### 常见 Lint 错误

| 错误 | 含义 | 修复方法 |
|------|------|----------|
| `unused-vars` | 未使用的变量 | 删除或添加 `_` 前缀 |
| `no-console` | 使用 console | 移除或使用 `console.error` |
| `react-hooks/exhaustive-deps` | Hook 依赖缺失 | 添加依赖或使用 `useCallback` |

---

## 代码审查清单

### 功能性

- [ ] 代码实现符合需求
- [ ] 边界情况被处理
- [ ] 错误处理适当
- [ ] 用户输入被验证

### 类型安全

- [ ] 无 `any` 类型
- [ ] Props 正确定义类型
- [ ] 数据库查询使用泛型
- [ ] 表单数据使用 Zod 验证

### 性能

- [ ] 无不必要的服务端组件转客户端
- [ ] 大列表考虑分页/虚拟化
- [ ] 图片使用 Next.js Image 组件
- [ ] 无内存泄漏（事件监听器清理）

### 可访问性

- [ ] 交互元素可键盘访问
- [ ] 表单输入有关联的 label
- [ ] 图标按钮有 aria-label
- [ ] 颜色对比度足够

### 代码质量

- [ ] 组件职责单一
- [ ] 函数命名清晰
- [ ] 无重复代码
- [ ] 注释解释"为什么"而非"是什么"

---

## 性能指南

### 服务端优先

```typescript
// 好的做法：服务端组件
export default async function Page() {
  const data = await fetchData();
  return <Table data={data} />;
}

// 避免：不必要的服务端获取转为客户端
'use client';
useEffect(() => {
  fetch('/api/data').then(r => r.json());
}, []);
```

### 图片优化

```typescript
// 使用 Next.js Image 组件
import Image from 'next/image';

<Image
  src={invoice.image_url}
  width={28}
  height={28}
  alt={`${invoice.name}的头像`}
/>
```

### 避免过度渲染

```typescript
// 使用 useMemo 缓存昂贵计算
const sortedData = useMemo(() => {
  return data.sort((a, b) => a.name.localeCompare(b.name));
}, [data]);
```

---

## 安全指南

### 用户输入

- **始终验证**表单数据（使用 Zod）
- **转义**用户生成的内容（React 默认转义）
- **参数化**数据库查询（使用 `sql` 模板标签）

### 敏感数据

```typescript
// 不要在客户端暴露敏感信息
// 错误
const API_KEY = 'secret-key'; // 不要在客户端组件中

// 正确：使用环境变量（服务端）
const apiKey = process.env.API_SECRET;
```

### 认证

- 使用 next-auth 管理会话
- 服务端操作检查认证状态
- 敏感操作使用服务端操作

---

## 交付前检查

提交代码前确保：

- [ ] `pnpm build` 成功
- [ ] 无 TypeScript 错误
- [ ] 无 ESLint 警告
- [ ] 手动测试通过
- [ ] 新功能有相应的类型定义
- [ ] 文档已更新（如适用）

---

## 资源

- [Next.js 文档](https://nextjs.org/docs)
- [React 文档](https://react.dev)
- [TypeScript 文档](https://www.typescriptlang.org/docs)
- [Tailwind CSS 文档](https://tailwindcss.com/docs)
- [Zod 文档](https://zod.dev)
