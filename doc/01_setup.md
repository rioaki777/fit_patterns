# 01. 環境構築・初期設定

## 前提条件

- Docker / Docker Compose がインストール済みであること
- Ruby 3.2.7 以上がインストール済みであること
- Bundler がインストール済みであること

---

## 手順

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd fit_patterns
```

### 2. Gem のインストール

```bash
bundle install
```

### 3. データベース（PostgreSQL）の起動

Docker Compose で PostgreSQL を起動します。

```bash
docker compose up -d
```

起動確認:

```bash
docker compose ps
# PostgreSQL コンテナが "running" 状態であることを確認
```

### 4. データベースの作成・マイグレーション

```bash
bundle exec rails db:create db:migrate
```

作成されるテーブル:

| テーブル | 用途 |
|----------|------|
| `users` | Devise による認証ユーザー |
| `weight_entries` | 日次体重・体脂肪率の記録 |
| `workouts` | 日次ワークアウト記録 |
| `weekly_reports` | 週次集計レポート |
| `audit_logs` | ポリモーフィック監査ログ |

### 5. サーバー起動

```bash
bundle exec rails server
```

ブラウザで http://localhost:3000 にアクセスします。

---

## テスト実行

```bash
# 全テスト
bundle exec rspec

# パターン別
bundle exec rspec spec/value_objects/
bundle exec rspec spec/workflows/
bundle exec rspec spec/services/

# 失敗したテストのみ再実行
bundle exec rspec --only-failures
```

---

## Rails コンソール

```bash
bundle exec rails console
```

コンソールでのデータ確認例:

```ruby
# ユーザー一覧
User.all

# 週次レポートと監査ログ
WeeklyReport.first&.audit_logs

# Value Object の使用例
w = BodyWeight.new(70_000)
w.to_kg     # => 70.0
w.formatted # => "70.0 kg"

# Period Value Object
p = Period.new(start_date: Date.today - 7, end_date: Date.today)
p.days   # => 8
p.covers?(Date.today) # => true
```

---

## ディレクトリ構成（主要部分）

```
fit_patterns/
├── app/
│   ├── adapters/          # Adapter パターン
│   ├── commands/          # Command パターン
│   ├── components/        # ViewComponent パターン
│   ├── controllers/       # Rails コントローラー
│   ├── forms/             # Form Object パターン
│   ├── jobs/              # ActiveJob (非同期)
│   ├── models/
│   │   └── concerns/      # Concern パターン
│   ├── policies/          # Policy Object パターン
│   ├── presenters/        # Presenter パターン
│   ├── queries/           # Query Object パターン
│   ├── services/          # Service Object パターン
│   ├── validators/        # Validator Object パターン
│   ├── value_objects/     # Value Object パターン
│   └── workflows/         # Workflow パターン
├── db/
│   ├── migrate/
│   └── schema.rb
└── spec/                  # RSpec テスト
```

---

次のステップ: [02_user_registration.md](02_user_registration.md)
