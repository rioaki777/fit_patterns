# 09. Workflow（ワークフロー）

## 概要

**複数のステップをトランザクションで束ね、順序を制御するオーケストレータークラス**。
Service Object や Query Object の「指揮者」として機能します。
副作用（DB 保存・非同期ジョブ・イベント通知）を1か所に集めます。

---

## 実装ファイル

`app/workflows/generate_weekly_report_workflow.rb`

```ruby
class GenerateWeeklyReportWorkflow
  def self.call(user:, form:)
    new(user:, form:).call
  end

  def initialize(user:, form:)
    @user = user
    @form = form
  end

  def call
    ActiveSupport::Notifications.instrument("weekly_report.generate") do
      ActiveRecord::Base.transaction do
        # Step 1: 集計
        stats  = WeeklyReport::Generate.call(user: @user, period: @form.period)

        # Step 2: 保存
        report = WeeklyReport.create!(
          user: @user,
          **stats,
          period_start: @form.period.start_date,
          period_end:   @form.period.end_date
        )

        # Step 3: 非同期通知のエンキュー
        SendWeeklyReportJob.perform_later(report.id, @form.notification_channel)

        report
      end
    end
  end
end
```

---

## 実行ステップの詳細

```
call メソッド
    │
    ├── [Pub/Sub] instrument("weekly_report.generate") 開始
    │
    └── [Transaction] 開始
            │
            ├── Step 1: WeeklyReport::Generate.call(...)
            │   （集計 → Hash を返す）
            │
            ├── Step 2: WeeklyReport.create!(...)
            │   │  DB にレポートを保存
            │   └── after_commit: AuditLog.create!  ← Callback
            │
            ├── Step 3: SendWeeklyReportJob.perform_later(...)
            │   （非同期ジョブをキューに積む）
            │
            └── report を返す
            │
    └── [Pub/Sub] instrument("weekly_report.generate") 終了
```

---

## トランザクションの重要性

```ruby
ActiveRecord::Base.transaction do
  stats  = WeeklyReport::Generate.call(...)  # 集計（読み取りのみ）
  report = WeeklyReport.create!(...)         # ← ここで例外が発生すると
  SendWeeklyReportJob.perform_later(...)     # ← ジョブのエンキューはロールバックされない
  report                                     #    （注: ジョブはトランザクション外で実行）
end
```

> **注意**: `ActiveJob` のジョブはトランザクションのロールバックと連動しません。
> DB 保存が失敗した場合でもジョブはキューに残る可能性があります。
> 本番環境では `after_commit` フックでジョブをエンキューするか、Transactional Outbox パターンを検討します。

---

## コンソールで確認

```ruby
user = User.first
form = WeeklyReportForm.new(
  period_start: Date.today - 7,
  period_end: Date.today,
  notification_channel: "email"
)

# Workflow を直接実行（通常は Command 経由）
report = GenerateWeeklyReportWorkflow.call(user: user, form: form)
report.class     # => WeeklyReport
report.persisted? # => true

# 監査ログも作成されていることを確認
report.audit_logs.count  # => 1
report.audit_logs.first.event  # => "weekly_report_created"
```

---

## Pub/Sub との連携

```ruby
# Workflow 内の instrument
ActiveSupport::Notifications.instrument("weekly_report.generate") do
  # ... 処理 ...
end

# 購読側（例: initializer や job で定義）
ActiveSupport::Notifications.subscribe("weekly_report.generate") do |name, start, finish, id, payload|
  duration_ms = ((finish - start) * 1000).round
  Rails.logger.info "[Event] #{name} completed in #{duration_ms}ms"
end
```

詳細: [12_pub_sub.md](12_pub_sub.md)

---

## Workflow のメリット

| 問題（コントローラー・モデルに手続きを書く） | 解決（Workflow） |
|----------------------------------------------|----------------|
| トランザクション管理がコントローラーに散在 | Workflow に集約 |
| ステップの順序が追いにくい | call メソッドに明示 |
| 複数の Service Object の協調が見えにくい | Workflow がオーケストレーション |
| テストでトランザクションのテストが難しい | Workflow を単体テストできる |

---

## 設計のポイント

- Workflow は「何を・どの順番で・どの条件で」を制御する
- Workflow 自身はビジネスロジックを持たない（それは Service Object の役割）
- `ActiveRecord::Base.transaction` は Workflow が責任を持つ
- エラーハンドリングは Command が担う（Workflow からの例外は Command で rescue）
