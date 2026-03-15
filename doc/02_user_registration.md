# 02. ユーザー登録・ログイン

このアプリは **Devise** による認証を使用しています。
全ての操作にはログインが必須です（`before_action :authenticate_user!`）。

---

## ユーザー登録

### 手順

1. ブラウザで http://localhost:3000/users/sign_up にアクセス
2. 以下の情報を入力して「Sign up」ボタンをクリック

| フィールド | 入力例 |
|------------|--------|
| Email | `test@example.com` |
| Password | `password123` |
| Password confirmation | `password123` |

### 成功時

- ログイン状態でルートページへリダイレクト
- Devise がセッションを自動管理

---

## ログイン

1. http://localhost:3000/users/sign_in にアクセス
2. 登録済みのメールアドレス・パスワードでログイン

---

## ログアウト

http://localhost:3000/users/sign_out へ DELETE リクエスト（ブラウザのリンクをクリック）

---

## 主要ルート一覧

```
GET  /users/sign_up    → ユーザー登録フォーム
POST /users            → ユーザー登録処理
GET  /users/sign_in    → ログインフォーム
POST /users/sign_in    → ログイン処理
DELETE /users/sign_out → ログアウト

GET  /weekly_reports        → レポート一覧
GET  /weekly_reports/new    → レポート生成フォーム
POST /weekly_reports        → レポート生成
GET  /weekly_reports/:id    → レポート詳細

GET  /weight_entries        → 体重記録一覧
POST /weight_entries        → 体重記録作成

GET  /workouts              → ワークアウト一覧
POST /workouts              → ワークアウト記録作成
```

---

## 関連するパターン

ログイン後のアクセス制御には **Policy Object** が使われます。

```ruby
# app/controllers/weekly_reports_controller.rb
before_action :authenticate_user!   # Devise: 未ログインは sign_in へリダイレクト

def create
  policy = WeeklyReportPolicy.new(current_user, nil)
  return redirect_to root_path, alert: "権限がありません" unless policy.create?
  # ...
end
```

詳細: [patterns/05_policy_object.md](patterns/05_policy_object.md)

---

次のステップ: [03_data_entry.md](03_data_entry.md)
