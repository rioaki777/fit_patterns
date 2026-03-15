# 04. 週次レポートの生成・確認

体重・ワークアウトデータが入力されたら、週次レポートを生成します。
このステップで **最も多くのデザインパターンが連鎖的に動作**します。

---

## レポート生成の手順

### 1. フォームを開く

http://localhost:3000/weekly_reports/new にアクセス

### 2. フォームに入力

| フィールド | 入力例 | 備考 |
|------------|--------|------|
| 開始日 | `2024-01-08` | |
| 終了日 | `2024-01-14` | 最大31日間、未来日不可 |
| 通知チャネル | `email` | `email` or `slack` |

### 3. 「生成」ボタンをクリック

成功すると、生成されたレポートの詳細ページへリダイレクトします。

---

## 内部で起きていること（パターンの連鎖）

フォーム送信から完了まで、以下の順番でパターンが動作します:

```
POST /weekly_reports
    │
    ▼
[1] WeeklyReportsController#create
    │  before_action: authenticate_user!    ← Devise
    │
    ▼
[2] WeeklyReportForm.new(params)            ← Form Object
    │  .valid? を呼ぶ
    │
    ▼
[3] SafePeriodValidator#validate            ← Validator Object
    │  - 開始日 > 終了日 → エラー
    │  - 終了日が未来 → エラー
    │  - 期間が31日超 → エラー
    │
    ▼
[4] WeeklyReportPolicy#create?             ← Policy Object
    │  current_user が存在するか確認
    │
    ▼
[5] GenerateWeeklyReportCommand.call(...)  ← Command
    │  Result struct を返す (success?, report, errors)
    │
    ▼
[6] GenerateWeeklyReportWorkflow.call(...) ← Workflow
    │  ActiveSupport::Notifications.instrument  ← Pub/Sub
    │  ActiveRecord::Base.transaction
    │
    ├─▼
    │ [7] WeeklyReport::Generate.call(...)      ← Service Object
    │      │
    │      ├── WeightEntriesQuery.call(...)     ← Query Object
    │      └── WorkoutsQuery.call(...)          ← Query Object
    │
    ├─▼
    │ [8] WeeklyReport.create!(...)             ← Callback
    │      after_commit → AuditLog.create!
    │
    └─▼
      [9] SendWeeklyReportJob.perform_later(...)← ActiveJob (非同期)
              │
              ▼
          [10] NotificationAdapter.for(channel) ← Adapter
                ├── MailNotificationAdapter     → メール送信
                └── SlackNotificationAdapter    → ログ出力
```

---

## レポートの確認

### 詳細ページ

リダイレクト先 `GET /weekly_reports/:id` では:

- **Presenter** が表示用データを整形
- **ViewComponent** が UI カードを描画
- **Value Object** がkg・%・kcal の単位変換

```
WeeklyReportPresenter
  ├── formatted_period    → "2024-01-08 〜 2024-01-14"
  ├── formatted_weight    → "70.5 kg"
  ├── formatted_fat       → "20.0%"
  ├── formatted_calories  → "1500 kcal"
  └── notification_label  → "送信済み 01/14 09:30"

WeeklySummaryCardComponent
  └── weekly_summary_card_component.html.erb
```

### 一覧ページ

http://localhost:3000/weekly_reports

- `Trackable` concern の `recently_modified` スコープで最近の10件を表示

---

## バリデーションエラーの確認

意図的にエラーを起こして Validator Object の動作を確認できます:

| 操作 | エラー内容 |
|------|-----------|
| 開始日 > 終了日で送信 | "period_start は終了日より前の日付を指定してください" |
| 終了日を未来日に設定 | "period_end は未来日を指定できません" |
| 32日以上の期間を指定 | "期間は31日以内にしてください" |
| 同一期間で重複生成 | DB の unique index エラー |

---

## 監査ログの確認

レポート生成後、`audit_logs` テーブルに自動的にレコードが作成されます。

Rails コンソールで確認:

```ruby
report = WeeklyReport.last
report.audit_logs

# => #<ActiveRecord::Associations::CollectionProxy [
#      #<AuditLog id: 1,
#                 auditable_type: "WeeklyReport",
#                 auditable_id: 1,
#                 event: "weekly_report_created",
#                 user_id: 1,
#                 payload: {"period_start"=>"2024-01-08",
#                           "period_end"=>"2024-01-14",
#                           "notified_at"=>nil}>
#    ]>
```

---

## Adapter の動作確認

`notification_channel` を変えてレポートを生成すると、異なる Adapter が使われます:

| channel | 使われる Adapter | 結果 |
|---------|-----------------|------|
| `email` | `MailNotificationAdapter` | `WeeklyReportMailer.deliver_later` |
| `slack` | `SlackNotificationAdapter` | `Rails.logger.info "[Slack] ..."` |

Slack の場合はログに以下が出力されます:

```
[Slack] Weekly report ready: 1
```

---

## Rails コンソールでの動作確認

個々のパターンをコンソールから直接呼び出して確認できます:

```ruby
user = User.first
period = Period.new(start_date: Date.today - 7, end_date: Date.today)
form = WeeklyReportForm.new(
  period_start: period.start_date,
  period_end: period.end_date,
  notification_channel: "email"
)

# バリデーション確認 (Form Object + Validator Object)
form.valid?
form.errors.full_messages

# Service Object 単体実行
stats = WeeklyReport::Generate.call(user: user, period: period)
# => { avg_weight_g: 70000, avg_body_fat_bp: 2000, ... }

# Command 経由で実行
result = GenerateWeeklyReportCommand.call(user: user, form: form)
result.success?
result.report
result.errors

# Adapter 単体確認
adapter = NotificationAdapter.for("slack")
adapter.deliver(report: WeeklyReport.last)
```

---

関連パターン一覧: [patterns/00_overview.md](patterns/00_overview.md)
