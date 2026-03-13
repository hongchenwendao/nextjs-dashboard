# 状态管理

> 本项目中状态的管理方式。

---

## 概述

本项目使用 **Next.js 15 App Router** 和 **服务端组件** 作为主要的状态管理策略。我们避免复杂的客户端状态管理库。

核心哲学：**服务端 > URL > 本地 > 全局**

- **服务端状态**: 在服务端组件中获取的数据
- **URL 状态**: 搜索、过滤、分页（通过 `searchParams`）
- **本地状态**: 使用 `useState` 的组件特定 UI 状态
- **全局状态**: 认证（next-auth），最小化使用

---

## 状态类别

### 1. 服务端状态（主要）

使用异步函数在服务端获取数据：

```typescript
// 服务端组件
export default async function InvoicesPage({
  searchParams,
}: {
  searchParams: { query?: string; page?: string };
}) {
  const query = searchParams.query || '';
  const currentPage = Number(searchParams.page) || 1;

  const invoices = await fetchFilteredInvoices(query, currentPage);
  const totalPages = await fetchInvoicesPages(query);

  return <InvoicesTable invoices={invoices} totalPages={totalPages} />;
}
```

**用于**:
- 数据库查询
- 外部服务 API 调用
- 需要 SEO 友好的数据

### 2. URL 状态

搜索、过滤和分页存储在 URL 中：

```typescript
'use client';

import { useSearchParams, useRouter } from 'next/navigation';

export function Search() {
  const searchParams = useSearchParams();
  const router = useRouter();

  const handleSearch = (term: string) => {
    const params = new URLSearchParams(searchParams);
    if (term) params.set('query', term);
    else params.delete('query');
    router.replace(`/dashboard/invoices?${params.toString()}`);
  };

  return <input onChange={(e) => handleSearch(e.target.value)} />;
}
```

**用于**:
- 搜索查询
- 过滤器选择
- 分页状态
- 可分享/可刷新的状态

### 3. 本地状态

使用 `useState` 的组件特定 UI 状态：

```typescript
'use client';

export function Modal() {
  const [isOpen, setIsOpen] = useState(false);
  const [selectedItem, setSelectedItem] = useState<string | null>(null);

  return (
    <>
      <button onClick={() => setIsOpen(true)}>打开</button>
      {isOpen && <Dialog onClose={() => setIsOpen(false)} />}
    </>
  );
}
```

**用于**:
- 模态框开/关
- 表单输入（提交前）
- 切换开关
- 手风琴展开状态
- 临时纯 UI 数据

### 4. 全局状态

仅用于：
- **认证**: next-auth 会话
- **主题**: 当前未实现

**避免用于全局状态**:
- 可以在服务端获取的数据
- 可以放在 URL 中的状态
- 组件特定的状态

---

## 何时使用全局状态

### 判断标准

仅在以下所有条件满足时提升到全局状态：

1. [ ] 被**树中不相关的组件**需要
2. [ ] 无法存储在 **URL** 中（不可分享/不可书签）
3. [ ] 无法在**服务端**获取（用户特定、动态）
4. [ ] 会导致**过度传递 props**

### 示例：可接受的全局状态

```typescript
// 好的做法：用户会话（由 next-auth 管理）
const session = await getServerSession();

// 好的做法：主题偏好（如果添加深色模式）
const { theme, setTheme } = useTheme();
```

### 示例：不应该是全局状态

```typescript
// 错误：发票列表（应服务端获取）
const [invoices, setInvoices] = useState([]);
// → 改用服务端组件

// 错误：搜索查询（应使用 URL）
const [query, setQuery] = useState('');
// → 改用 searchParams

// 错误：表单数据（本地于表单）
const globalFormData = useFormStore();
// → 保持为表单组件的本地状态
```

---

## 服务端状态

### 获取模式

所有数据获取在 `app/lib/data.ts` 中：

```typescript
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

### 缓存

Next.js 自动缓存服务端组件的 fetch 结果。要重新验证：

```typescript
// 在服务端操作中添加重新验证
export async function createInvoice(formData: FormData) {
  // 变更数据库
  await sql`INSERT INTO invoices ...`;

  // 重新验证缓存
  revalidatePath('/dashboard/invoices');
}
```

### 不使用客户端数据获取库

**不要添加** React Query、SWR 或类似库，除非：
- 你需要乐观更新
- 你有复杂的缓存失效需求
- 服务端组件无法处理该用例

---

## 派生状态

### 渲染时计算

不要存储派生状态 - 直接计算：

```typescript
// 错误：存储派生状态
const [fullName, setFullName] = useState('');
const [firstName, lastName] = useState('', '');

useEffect(() => {
  setFullName(`${firstName} ${lastName}`);
}, [firstName, lastName]);

// 正确：渲染时计算
const fullName = `${firstName} ${lastName}`;
```

### 对昂贵计算使用 useMemo

```typescript
const expensiveValue = useMemo(() => {
  return computeExpensiveValue(data);
}, [data]);
```

---

## 常见错误

| 错误 | 为什么错 | 正确做法 |
|------|----------|----------|
| 服务端数据用全局状态 | 服务端组件更简单 | 使用服务端组件获取 |
| 初始数据客户端获取 | 更慢、SEO 差 | 使用异步服务端组件 |
| URL 状态不在 URL 中 | 无法分享/书签 | 使用 searchParams |
| 存储派生状态 | 值可能过时、复杂 | 渲染时计算 |
| 过度使用 Zustand/Redux | 不必要的复杂度 | 服务端组件 + URL 状态 |
| 警告 props 传递 | 通常为时过早的优化 | 2-3 层的 props 传递没问题 |

---

## 示例

| 文件 | 状态模式 |
|------|----------|
| [app/dashboard/invoices/page.tsx](../../app/dashboard/invoices/page.tsx) | 服务端 + URL 状态 |
| [app/ui/search.tsx](../../app/ui/search.tsx) | 带防抖的 URL 状态 |
| [app/ui/invoices/create-form.tsx](../../app/ui/invoices/create-form.tsx) | 本地状态（如需要） |
| [app/lib/data.ts](../../app/lib/data.ts) | 服务端数据获取 |

---

## 决策树

```
需要管理状态？
│
├─ 是来自 DB/API 的数据吗？
│  └─ 是：使用服务端组件（在 data.ts 中获取）
│
├─ 是搜索/过滤/分页吗？
│  └─ 是：使用 URL 状态（searchParams）
│
├─ 是纯 UI（模态框、表单输入）吗？
│  └─ 是：使用本地 useState
│
└─ 被不相关的组件需要吗？
   └─ 是：考虑全局状态（但要三思！）
```

---

## 未来：如果状态需求增长

如果应用变得更复杂，可以考虑添加：

1. **Zustand** 用于客户端全局状态
2. **React Query** 如果需要激进的客户端缓存
3. **服务端操作** 用于变更（已可用）

但记住：**服务端组件能处理大多数状态需求。**
