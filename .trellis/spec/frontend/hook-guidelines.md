# Hook 指南

> 本项目中 Hooks 的使用方式。

---

## 概述

这是一个 **Next.js 15 App Router** 应用，意味着 **服务端组件是默认的**。React hooks（`useState`、`useEffect` 等）仅在客户端组件中使用（需标记 `'use client'`）。

核心原则：

- 优先使用服务端组件和服务端操作，而非客户端 hooks
- Hooks 仅用于交互式 UI 状态（表单、搜索、模态框）
- 数据获取主要在服务端进行（`app/lib/data.ts` 中的异步函数）

---

## 自定义 Hook 模式

### 当前自定义 Hooks

本项目目前自定义 hooks 较少。大多数数据获取在服务端进行。

创建自定义 hook 时，遵循以下模式：

```typescript
'use client';

import { useState, useCallback } from 'react';

export function useSearch() {
  const [query, setQuery] = useState('');

  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setQuery(e.target.value);
  }, []);

  return { query, setQuery, handleChange };
}
```

### 命名约定

- 自定义 hooks **必须** 以 `use` 开头
- 使用 camelCase 命名
- 如有特定域，添加前缀：`useInvoiceForm`、`useCustomerTable`

```typescript
// 好的做法
useSearch()
usePagination()
useFormState()

// 错误的做法
getSearch()
SearchHook()
use_search()
```

---

## 数据获取

### 主要方式：服务端异步函数

**本项目不使用** React Query、SWR 或其他客户端数据获取库。

数据获取在服务端组件中使用 `app/lib/data.ts` 中的异步函数：

```typescript
// 在服务端组件中
export default async function InvoicesTable({ query, currentPage }: { query: string; currentPage: number }) {
  const invoices = await fetchFilteredInvoices(query, currentPage);

  return <table>{/* 渲染发票 */}</table>;
}
```

### 服务端操作处理变更

对于变更操作（创建、更新、删除），使用服务端操作：

```typescript
'use server';

export async function createInvoice(formData: FormData) {
  // 验证并变更数据
  // 重新验证缓存
}
```

### 客户端获取

仅在以下情况使用客户端 hooks：
- 实时更新（当前未实现）
- 搜索防抖（使用 `use-debounce` 包）

```typescript
'use client';

import { useDebouncedCallback } from 'use-debounce';

export function Search({ placeholder }: { placeholder: string }) {
  const handleSearch = useDebouncedCallback((term: string) => {
    // 更新 URL 参数进行服务端过滤
  }, 300);

  return (
    <input
      onChange={(e) => handleSearch(e.target.value)}
    />
  );
}
```

---

## 何时使用客户端 Hooks

在客户端组件中使用 hooks：

| 用例 | Hook | 示例 |
|------|------|------|
| 本地 UI 状态 | `useState` | 模态框开/关、下拉展开 |
| 表单输入 | `useState` | 受控输入值 |
| 副作用 | `useEffect` | 浏览器 API、分析统计 |
| 派生状态 | `useMemo` | 昂贵计算 |
| 稳定引用 | `useCallback` | 传递给子组件的事件处理器 |
| Refs | `useRef` | DOM 元素访问、存储非响应式值 |

### 示例：搜索组件

```typescript
'use client';

import { useDebouncedCallback } from 'use-debounce';
import { useSearchParams, useRouter } from 'next/navigation';

export function Search({ placeholder }: { placeholder: string }) {
  const searchParams = useSearchParams();
  const router = useRouter();

  const handleSearch = useDebouncedCallback((term: string) => {
    const params = new URLSearchParams(searchParams);
    if (term) {
      params.set('query', term);
    } else {
      params.delete('query');
    }
    router.replace(`/dashboard/invoices?${params.toString()}`);
  }, 300);

  return (
    <input
      className="..."
      placeholder={placeholder}
      onChange={(e) => handleSearch(e.target.value)}
      defaultValue={searchParams.get('query')?.toString()}
    />
  );
}
```

---

## 第三方 Hooks

### 当前使用

| 包 | Hook | 用途 |
|------|------|------|
| `use-debounce` | `useDebouncedCallback` | 搜索输入防抖 |

### 添加新 Hook 库

添加新的 hook 库之前：
1. 检查问题是否可以在服务端解决
2. 优先使用原生 Next.js 模式（useSearchParams、useRouter）
3. 保持依赖最小化

---

## 共享有状态逻辑

### 优先使用服务端组件数据传递

而非复杂的状态管理：

```typescript
// 好的做法 - 服务端组件传递数据
export default async function Page({ searchParams }: { searchParams: { query?: string } }) {
  const query = searchParams.query || '';
  const invoices = await fetchFilteredInvoices(query, currentPage);

  return <InvoicesTable invoices={invoices} />;
}
```

### 仅客户端状态

使用组合来共享状态：

```typescript
// 父组件持有状态，子组件接收为 props
export function InvoiceForm() {
  const [status, setStatus] = useState<'pending' | 'paid'>('pending');

  return (
    <>
      <StatusSelector value={status} onChange={setStatus} />
      <FormFooter status={status} />
    </>
  );
}
```

### Context（谨慎使用）

仅将 React Context 用于：
- 用户认证状态（由 next-auth 处理）
- 主题（深色/浅色模式）- 当前未实现

---

## 常见错误

| 错误 | 为什么错 | 正确做法 |
|------|----------|----------|
| 使用 `useEffect` 获取数据 | 服务端组件更快 | 使用服务端组件中的异步函数 |
| 在多个组件中获取相同数据 | 重复请求 | 在父组件中获取一次，传递为 props |
| 复杂的客户端状态 | 难以维护 | 尽可能推到服务端 |
| 为简单逻辑创建 hook | 不必要的抽象 | 直接使用 hooks |
| 忘记 `'use client'` 指令 | 使用 hooks 会运行时错误 | 使用 hooks 时添加指令 |
| 搜索输入不防抖 | 过度渲染/请求 | 使用 `use-debounce` |

---

## 示例

| 文件 | 使用的模式 |
|------|-----------|
| [app/ui/search.tsx](../../app/ui/search.tsx) | `useSearchParams`、`useDebouncedCallback` |
| [app/ui/dashboard/sidenav.tsx](../../app/ui/dashboard/sidenav.tsx) | 无 hooks - 服务端组件 |
| [app/ui/invoices/table.tsx](../../app/ui/invoices/table.tsx) | 服务端数据获取 |

---

## 未来考虑

如果应用扩展，可以考虑添加：

1. **常见模式的自定义 hooks**：
   - `usePagination()` - 提取分页逻辑
   - `useTableSort()` - 表格排序状态

2. **客户端状态管理**（仅在必要时）：
   - Zustand 用于复杂客户端状态
   - React Query 用于激进缓存（如果服务端不够用）

但记住：**服务端组件 + URL 状态应该能处理大多数情况。**
