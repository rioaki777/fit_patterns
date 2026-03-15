# fit_patterns

Railsアプリで主に扱われる15 種類以上のデザインパターンを「一つの流れ」で触れる学習用アプリ。

「週次レポート生成 → 通知 → 保存 → 監査ログ」というユースケースに沿って、デザインパターンを段階的に実装している。

---

## 技術スタック

| 項目 | バージョン |
|---|---|
| Ruby | 3.2.7 |
| Rails | 8.0.x |
| DB | PostgreSQL 16 (Docker) |
| 認証 | Devise |
| UI コンポーネント | ViewComponent |
| テスト | RSpec / FactoryBot / shoulda-matchers |

---

## セットアップ（初回）

### 前提条件

- Docker Desktop がインストール済みで起動していること
- WSL2 を使っている場合は Docker Desktop の WSL Integration が有効になっていること
- Ruby / Bundler はホストにインストール不要（すべて Docker 内で実行）

### 手順

```bash
# 1. リポジトリをクローン
git clone <repository-url>
cd fit_patterns

# 2. イメージをビルド
docker compose build

# 3. gem をインストール
docker compose run --rm app bundle install

# 4. コンテナを起動
docker compose up -d

# 5. DB を作成してマイグレーションを実行
docker compose exec app bundle exec rails db:create db:migrate
```

ブラウザで http://localhost:3000 を開き、`/users/sign_up` でアカウントを作成してログインする。

---

## Docker

### サービス操作

```bash
# 起動
docker compose up -d

# 停止
docker compose stop

# 停止 + ボリューム削除（DBを初期化したいとき）
docker compose down -v

# ログ確認
docker compose logs -f app
docker compose logs db

# コンテナ状態確認
docker compose ps
```

### gem の更新

```bash
# Gemfile を編集後
docker compose run --rm app bundle install
```

### DB 接続情報（開発・テスト共通）

| 項目 | 値 |
|---|---|
| host | db（コンテナ内） / localhost（ホストから） |
| port | 5432 |
| user | postgres |
| password | postgres |

---

## テスト

```bash
# 全テスト実行
docker compose exec app bundle exec rspec

# ディレクトリ指定
docker compose exec app bundle exec rspec spec/value_objects/
docker compose exec app bundle exec rspec spec/services/
docker compose exec app bundle exec rspec spec/workflows/

# ファイル指定
docker compose exec app bundle exec rspec spec/models/weekly_report_spec.rb

# 失敗したテストだけ再実行
docker compose exec app bundle exec rspec --only-failures
```

### テスト構成

| spec | 対象パターン |
|---|---|
| `spec/value_objects/period_spec.rb` | Value Object |
| `spec/value_objects/body_weight_spec.rb` | Value Object |
| `spec/validators/safe_period_validator_spec.rb` | Validator Object |
| `spec/queries/weight_entries_query_spec.rb` | Query Object |
| `spec/queries/workouts_query_spec.rb` | Query Object |
| `spec/services/weekly_report/generate_spec.rb` | Service Object |
| `spec/commands/generate_weekly_report_command_spec.rb` | Command |
| `spec/workflows/generate_weekly_report_workflow_spec.rb` | Workflow |
| `spec/jobs/send_weekly_report_job_spec.rb` | ActiveJob + Adapter |
| `spec/policies/weekly_report_policy_spec.rb` | Policy Object |
| `spec/components/weekly_summary_card_component_spec.rb` | ViewComponent |
| `spec/models/weekly_report_spec.rb` | Callback / Concern |

---

## 実装パターン一覧

ユースケース：**週次レポート生成 → 通知 → 保存 → 監査ログ**

```
Controller
  └─ WeeklyReportPolicy          # Policy Object    権限チェック
  └─ WeeklyReportForm            # Form Object      入力バリデーション
       └─ SafePeriodValidator    # Validator Object 期間チェック
       └─ Period                 # Value Object     期間の表現
  └─ GenerateWeeklyReportCommand # Command          実行単位
       └─ GenerateWeeklyReportWorkflow  # Workflow  ステップ管理
            └─ WeeklyReport::Generate  # Service   集計ロジック
                 └─ WeightEntriesQuery # Query Object
                 └─ WorkoutsQuery      # Query Object
            └─ WeeklyReport.create!    # ActiveRecord + Callback → AuditLog
                 └─ Trackable          # Concern    共通スコープ/ログ
                 └─ BodyWeight         # Value Object
                 └─ BodyFatRate        # Value Object
                 └─ Calories           # Value Object
            └─ SendWeeklyReportJob     # ActiveJob  非同期通知
                 └─ NotificationAdapter.for(channel)  # Adapter
                      └─ MailNotificationAdapter
                      └─ SlackNotificationAdapter
            └─ ActiveSupport::Notifications  # Pub/Sub 計測イベント
  └─ WeeklyReportPresenter       # Presenter  表示整形
       └─ WeeklySummaryCardComponent  # ViewComponent
```

### パターンとファイルの対応

| パターン | ファイル |
|---|---|
| Value Object | `app/value_objects/{period,body_weight,body_fat_rate,calories}.rb` |
| Validator Object | `app/validators/safe_period_validator.rb` |
| Concern | `app/models/concerns/trackable.rb` |
| Query Object | `app/queries/{weight_entries,workouts}_query.rb` |
| Policy Object | `app/policies/weekly_report_policy.rb` |
| Form Object | `app/forms/weekly_report_form.rb` |
| Service Object | `app/services/weekly_report/generate.rb` |
| Command | `app/commands/generate_weekly_report_command.rb` |
| Adapter | `app/adapters/{notification,mail_notification,slack_notification}_adapter.rb` |
| ActiveJob | `app/jobs/send_weekly_report_job.rb` |
| Pub/Sub | `SendWeeklyReportJob` / `GenerateWeeklyReportWorkflow` 内の `instrument` 呼び出し |
| Workflow | `app/workflows/generate_weekly_report_workflow.rb` |
| Presenter | `app/presenters/weekly_report_presenter.rb` |
| ViewComponent | `app/components/weekly_summary_card_component.rb` |
| Callback | `WeeklyReport#write_audit_log`（`after_commit`） |

---

## 主要エンドポイント

| URL | 説明 |
|---|---|
| `GET /users/sign_up` | アカウント登録 |
| `GET /users/sign_in` | ログイン |
| `GET /weekly_reports` | レポート一覧（Trackable scope） |
| `GET /weekly_reports/new` | レポート生成フォーム（Form Object） |
| `POST /weekly_reports` | レポート生成（Command → Workflow → Service） |
| `GET /weekly_reports/:id` | レポート詳細（Presenter + ViewComponent） |
| `GET /weight_entries` | 体重記録 CRUD |
| `GET /workouts` | ワークアウト記録 CRUD |

---

## DB マイグレーション

```bash
# マイグレーション実行
docker compose exec app bundle exec rails db:migrate

# テスト DB を最新化
docker compose exec app bundle exec rails db:test:prepare

# スキーマ確認
docker compose exec app bundle exec rails db:schema:dump
```

---

## よくある操作

```bash
# Rails コンソール
docker compose exec app bundle exec rails console

# ルーティング確認
docker compose exec app bundle exec rails routes | grep weekly

# アプリログ確認
docker compose logs -f app

# git 操作はホストで実行
git status
git commit -m "..."
```
