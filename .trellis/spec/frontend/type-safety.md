# 类型安全

> 本项目的类型安全模式。

---

## 概述

本项目使用 **TypeScript** 启用严格模式，配合 **Zod** 进行运行时验证。

核心原则：

- 所有类型手动定义（无 ORM 代码生成）
- 编译时类型检查通过 TypeScript
- 运行时验证通过 Zod
- 避免使用 `any` 和类型断言

---

## 类型组织

### 集中式类型定义

所有领域类型定义在 `app/lib/definitions.ts` 中：

```typescript
// app/lib/definitions.ts

// 数据库实体类型
export type User = {
  id: string;
  name: string;
  email: string;
  password: string;
};

export type Customer = {
  id: string;
  name: string;
  email: string;
  image_url: string;
};

export type Invoice = {
  id: string;
  customer_id: string;
  amount: number;
  date: string;
  status: 'pending' | 'paid'; // 字符串字面量联合类型
};
```

### 类型变体

使用工具类型创建变体：

```typescript
// 原始类型（来自数据库）
export type LatestInvoiceRaw = Omit<LatestInvoice, 'amount'> & {
  amount: number;
};

// 格式化后的类型（用于 UI）
export type LatestInvoice = {
  id: string;
  name: string;
  image_url: string;
  email: string;
  amount: string; // 格式化为货币字符串
};

// 表格特定类型
export type InvoicesTable = {
  id: string;
  customer_id: string;
  name: string;
  email: string;
  image_url: string;
  date: string;
  amount: number;
  status: 'pending' | 'paid';
};
```

### 本地类型

组件特定的 props 类型可以在组件文件中定义：

```typescript
// app/ui/invoices/create-form.tsx
interface FormProps {
  customers: CustomerField[];
}

export default function Form({ customers }: FormProps) {
  // ...
}
```

---

## 验证

### Zod 模式定义

使用 Zod 定义和验证表单数据：

```typescript
import { z } from 'zod';

// 定义验证模式
export const FormSchema = z.object({
  id: z.string(),
  customerId: z.string({
    invalid_type_error: '请选择客户',
  }),
  amount: z.coerce
    .number()
    .gt(0, { message: '请输入大于 0 的金额' }),
  status: z.enum(['pending', 'paid'], {
    invalid_type_error: '请选择发票状态',
  }),
});

// 从模式推断类型
export type FormState = {
  errors?: {
    customerId?: string[];
    amount?: string[];
    status?: string[];
  };
  message?: string | null;
};
```

### 使用 Zod 验证

```typescript
'use server';

import { z } from 'zod';

export async function createInvoice(formData: FormData) {
  // 解析和验证
  const validatedFields = FormSchema.safeParse({
    customerId: formData.get('customerId'),
    amount: formData.get('amount'),
    status: formData.get('status'),
  });

  // 处理验证错误
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      message: '缺失字段。无法创建发票。',
    };
  }

  // 使用验证后的数据
  const { customerId, amount, status } = validatedFields.data;
  // ...
}
```

---

## 常见模式

### 字符串字面量联合类型

用于有限选项的枚举：

```typescript
export type Invoice = {
  status: 'pending' | 'paid'; // 只能是这两个值之一
};
```

### 工具类型

使用 TypeScript 内置工具类型：

```typescript
// Omit - 排除某些属性
export type LatestInvoiceRaw = Omit<LatestInvoice, 'amount'> & {
  amount: number;
};

// Pick - 只选择某些属性
export type CustomerField = Pick<Customer, 'id' | 'name'>;

// Partial - 所有属性可选
type PartialInvoice = Partial<Invoice>;

// Required - 所有属性必需
type RequiredInvoice = Required<PartialInvoice>;
```

### 数据库查询类型

使用泛型进行类型推断：

```typescript
// 指定返回类型
const data = await sql<Revenue[]>`SELECT * FROM revenue`;

// 类型推断工作正常
const revenue = data[0].revenue; // 类型为 number
```

---

## 禁止模式

| 模式 | 为什么禁止 | 替代方案 |
|------|------------|----------|
| `any` 类型 | 失去类型安全 | 使用具体类型或 `unknown` |
| `as` 类型断言 | 可能隐藏错误 | 使用类型守卫或 Zod 解析 |
| `@ts-ignore` | 完全禁用检查 | 修复底层类型问题 |
| 可选属性滥用 `?` | 意外的 undefined | 使用明确的联合类型 |
| `interface` 存储数据 | 应使用 `type` | 数据结构用 `type`，对象形状用 `interface` |

### 类型断言 vs 类型守卫

```typescript
// 错误：类型断言
const value = data as string;

// 正确：类型守卫
function isString(value: unknown): value is string {
  return typeof value === 'string';
}

if (isString(data)) {
  // data 在此处为 string
}
```

### Zod 替代类型断言

```typescript
// 错误：断言外部数据
const user = userData as User;

// 正确：验证然后解析
const user = UserSchema.parse(userData);
```

---

## 类型安全的数据库查询

### 带类型的 SQL 查询

```typescript
// 定义返回类型
const data = await sql<Invoice[]>`
  SELECT * FROM invoices
`;

// 类型推断自动工作
data.map((invoice) => {
  // invoice.amount 类型为 number
  // invoice.status 类型为 'pending' \| 'paid'
});
```

### 金额处理（分为单位）

金额以"分"为单位存储为整数：

```typescript
// 数据库中：5000 = $50.00
export type Invoice = {
  amount: number; // 分为单位
};

// 转换为美元显示
export const formatCurrency = (amount: number) => {
  return (amount / 100).toLocaleString('en-US', {
    style: 'currency',
    currency: 'USD',
  });
};
```

---

## 常见错误

| 错误 | 为什么错 | 正确做法 |
|------|----------|----------|
| API 响应用 `any` | 无类型检查 | 定义响应接口 |
| 表单数据不验证 | 运行时错误 | 使用 Zod 验证 |
| 类型与数据库不同步 | 隐蔽的 bug | 保持 definitions.ts 更新 |
| `console.log` 输出用 `any` | 调试困难 | 使用正确的类型或 `unknown` |
| 分散的类型定义 | 难以维护 | 集中在 definitions.ts |

---

## 配置

### tsconfig.json

```json
{
  "compilerOptions": {
    "strict": true,           // 启用所有严格选项
    "noEmit": true,           // 不生成输出文件
    "esModuleInterop": true,  // ES 模块互操作
    "skipLibCheck": true      // 跳过库文件检查（加快编译）
  }
}
```

---

## 示例

| 文件 | 类型模式 |
|------|----------|
| [app/lib/definitions.ts](../../app/lib/definitions.ts) | 所有领域类型定义 |
| [app/lib/data.ts](../../app/lib/data.ts) | 带类型的数据库查询 |
| [app/ui/invoices/create-form.tsx](../../app/ui/invoices/create-form.tsx) | Props 类型定义 |

---

## 类型安全清单

添加新功能时：

- [ ] 在 `definitions.ts` 中定义类型
- [ ] 数据库查询使用泛型 `sql<Type[]>`
- [ ] 表单数据使用 Zod 验证
- [ ] 避免 `any` 和类型断言
- [ ] 使用字符串字面量联合类型表示枚举
