# 组件指南

> 本项目的组件构建方式。

---

## 概述

本项目使用 **函数组件** 配合 **TypeScript** 和 **Tailwind CSS**。组件按功能域分组，而非按组件类型。

核心模式：

- 函数组件，使用 TypeScript 接口定义 props
- 使用 Tailwind CSS 样式（不使用 CSS modules 或 styled-components）
- 默认使用服务端组件（Client Components 需标记 `'use client'`）
- 可复用组件使用命名导出，页面使用默认导出
- 优先使用组合而非复杂的 props 传递

---

## 组件结构

### 标准结构

```typescript
// 1. 导入（外部依赖优先，然后内部导入）
import Link from 'next/link';
import { PencilIcon } from '@heroicons/react/24/outline';
import { Button } from '@/app/ui/button';

// 2. 类型/接口（如果 props 复杂）
interface TableProps {
  query: string;
  currentPage: number;
}

// 3. 组件（页面用默认导出，可复用组件用命名导出）
export default async function InvoicesTable({ query, currentPage }: TableProps) {
  // 4. 数据获取（用于服务端组件）
  const invoices = await fetchFilteredInvoices(query, currentPage);

  // 5. 渲染
  return (
    <div className="mt-6 flow-root">
      {/* JSX */}
    </div>
  );
}
```

### 示例：简单组件

```typescript
// app/ui/button.tsx
import clsx from 'clsx';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
}

export function Button({ children, className, ...rest }: ButtonProps) {
  return (
    <button
      {...rest}
      className={clsx(
        'flex h-10 items-center rounded-lg bg-blue-500 px-4 text-sm font-medium text-white transition-colors hover:bg-blue-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 active:bg-blue-600 aria-disabled:cursor-not-allowed aria-disabled:opacity-50',
        className,
      )}
    >
      {children}
    </button>
  );
}
```

### 示例：带数据获取的服务端组件

```typescript
// app/ui/invoices/table.tsx
import { fetchFilteredInvoices } from '@/app/lib/data';

export default async function InvoicesTable({ query, currentPage }: { query: string; currentPage: number }) {
  const invoices = await fetchFilteredInvoices(query, currentPage);

  return (
    <div className="mt-6 flow-root">
      <table className="hidden min-w-full text-gray-900 md:table">
        {/* 表格内容 */}
      </table>
    </div>
  );
}
```

---

## Props 约定

### 接口定义

- 使用 `interface` 定义 props（而非 `type`）
- 适当时继承标准 HTML 属性
- 使用描述性名称

```typescript
// 好的做法 - 继承 HTML 属性
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
}

// 好的做法 - 明确的 props
interface FormProps {
  customers: CustomerField[];
}

// 避免 - 过于通用
interface Props {
  data: any;
  onClick: any;
}
```

### 常见 Props 模式

| 模式 | 示例 |
|------|------|
| 子元素 | `children: React.ReactNode` |
| 可选属性 | `className?: string` |
| 回调函数 | `onSelect?: (id: string) => void` |
| 布尔标志 | `disabled?: boolean` |
| 数据 | `invoices: Invoice[]` |

---

## 样式模式

### Tailwind CSS - 主要方法

所有样式使用 **Tailwind CSS 工具类**。不使用 CSS modules 或 styled-components。

```typescript
// 类名应按逻辑排序：布局 -> 间距 -> 视觉效果
<div className="mt-6 flow-root">
  <div className="inline-block min-w-full align-middle">
    <div className="rounded-lg bg-gray-50 p-2 md:pt-0">
      {/* 内容 */}
    </div>
  </div>
</div>
```

### 使用 clsx 进行条件样式

使用 `clsx` 进行条件类名合并：

```typescript
import clsx from 'clsx';

<button
  className={clsx(
    'base-classes',
    isActive && 'active-classes',
    className // 允许通过 prop 覆盖
  )}
>
```

### 响应式设计

使用 Tailwind 的响应式前缀：

```typescript
<div className="flex h-10 items-center">
  <span className="hidden md:block">在 md+ 可见</span>
  <span className="md:hidden">仅移动端可见</span>
</div>
```

---

## 服务端组件 vs 客户端组件

### 默认：服务端组件

组件默认是服务端组件。仅在以下情况添加 `'use client'`：

- 事件处理器（`onClick`、`onChange`）
- React hooks（`useState`、`useEffect`）
- 浏览器 API（`window`、`localStorage`）

### 客户端组件模式

```typescript
'use client';

import { useState } from 'react';

export function SearchBar() {
  const [query, setQuery] = useState('');

  return (
    <input
      value={query}
      onChange={(e) => setQuery(e.target.value)}
    />
  );
}
```

### 提示：保持客户端组件小巧

将客户端逻辑提取到小组件，其余保持为服务端组件：

```typescript
// 服务端组件（默认）
export default function Page() {
  return (
    <div>
      <h1>仪表板</h1>
      <ClientSearch /> {/* 仅这是客户端 */}
      <ServerTable query={query} />
    </div>
  );
}
```

---

## 无障碍标准

### 必需属性

- 使用语义化 HTML（`<button>`、`<a>`、`<label>`）
- 为纯图标按钮添加 `aria-label`
- 表单输入使用 `<label htmlFor>`
- 为屏幕阅读器添加 `sr-only` 文本

```typescript
// 带无障碍支持的图标按钮
<button type="submit" className="rounded-md border p-2 hover:bg-gray-100">
  <span className="sr-only">删除</span>
  <TrashIcon className="w-5" />
</button>

// 带 htmlFor 的表单标签
<label htmlFor="customer" className="mb-2 block text-sm font-medium">
  选择客户
</label>
<select id="customer" name="customerId">
  {/* 选项 */}
</select>
```

### 焦点样式

所有交互元素需要可见的焦点状态：

```typescript
className="... focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
```

---

## 常见错误

| 错误 | 为什么错 | 正确做法 |
|------|----------|----------|
| Props 使用 `any` | 失去类型安全 | 使用正确的接口 |
| 渲染中内联函数 | 每次渲染创建新函数 | 使用 `useCallback` 或提取函数 |
| 巨大的组件 | 难以理解/维护 | 拆分成小组件 |
| 在 JS 文件中写 CSS | 不是我们的模式 | 使用 Tailwind 类 |
| 忘记 `'use client'` | 使用 hooks 会运行时错误 | 使用 hooks 时添加指令 |
| 不处理加载状态 | 用户体验差 | 使用 loading.tsx 或 Suspense |

---

## 示例

实现良好的组件：

- [Button](../../app/ui/button.tsx) - 带属性扩展的简单可复用组件
- [SideNav](../../app/ui/dashboard/sidenav.tsx) - 布局组件
- [InvoicesTable](../../app/ui/invoices/table.tsx) - 带数据获取的服务端组件
- [CreateForm](../../app/ui/invoices/create-form.tsx) - 复杂表单组件
