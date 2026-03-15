# fit_patterns ドキュメント

このディレクトリは、**fit_patterns** アプリの操作手順とデザインパターン解説をまとめたものです。

## ユースケース

```
週次レポート生成 → 通知 → 保存 → 監査ログ
```

このユースケースを通じて、Railsアプリで実践的に使われる **15以上のデザインパターン** を学びます。

---

## 操作手順ドキュメント

| ファイル | 内容 |
|----------|------|
| [01_setup.md](01_setup.md) | 環境構築・初期設定 |
| [02_user_registration.md](02_user_registration.md) | ユーザー登録・ログイン |
| [03_data_entry.md](03_data_entry.md) | 体重・ワークアウトの記録 |
| [04_report_generation.md](04_report_generation.md) | 週次レポートの生成・確認 |

---

## デザインパターン解説

| ファイル | パターン | 発動タイミング |
|----------|----------|----------------|
| [patterns/00_overview.md](patterns/00_overview.md) | 全体マップ | — |
| [patterns/01_value_object.md](patterns/01_value_object.md) | Value Object | レポート表示時 |
| [patterns/02_validator_object.md](patterns/02_validator_object.md) | Validator Object | フォーム送信時 |
| [patterns/03_concern.md](patterns/03_concern.md) | Concern | モデル読み込み時 |
| [patterns/04_query_object.md](patterns/04_query_object.md) | Query Object | レポート集計時 |
| [patterns/05_policy_object.md](patterns/05_policy_object.md) | Policy Object | アクセス制御時 |
| [patterns/06_form_object.md](patterns/06_form_object.md) | Form Object | フォーム受信時 |
| [patterns/07_service_object.md](patterns/07_service_object.md) | Service Object | 集計ロジック実行時 |
| [patterns/08_command.md](patterns/08_command.md) | Command | コントローラーから呼び出し時 |
| [patterns/09_workflow.md](patterns/09_workflow.md) | Workflow | トランザクション実行時 |
| [patterns/10_adapter.md](patterns/10_adapter.md) | Adapter | 通知チャネル切替時 |
| [patterns/11_active_job.md](patterns/11_active_job.md) | ActiveJob | 非同期通知実行時 |
| [patterns/12_pub_sub.md](patterns/12_pub_sub.md) | Pub/Sub | イベント発行・購読時 |
| [patterns/13_presenter.md](patterns/13_presenter.md) | Presenter | ビュー表示時 |
| [patterns/14_view_component.md](patterns/14_view_component.md) | ViewComponent | UIコンポーネント表示時 |
| [patterns/15_callback.md](patterns/15_callback.md) | Callback | DB保存後の監査ログ |

---

## リクエストフロー全体図

```
[ブラウザ] POST /weekly_reports
    ↓
WeeklyReportsController#create
    ↓ Policy Object (認可チェック)
    ↓
GenerateWeeklyReportCommand.call(user:, form:)
    ↓ Form Object (バリデーション)  ← Validator Object
    ↓
GenerateWeeklyReportWorkflow.call(user:, form:)
    ↓ Pub/Sub: instrument("weekly_report.generate")
    ↓ ActiveRecord::Base.transaction
    ↓
    ├── WeeklyReport::Generate.call(user:, period:)  ← Service Object
    │       ↓ WeightEntriesQuery.call(...)           ← Query Object
    │       ↓ WorkoutsQuery.call(...)                ← Query Object
    │
    ├── WeeklyReport.create!(...)                    ← Callback → AuditLog
    │
    └── SendWeeklyReportJob.perform_later(...)       ← ActiveJob
            ↓ (非同期)
            NotificationAdapter.for(channel)         ← Adapter
                ↓
                MailNotificationAdapter / SlackNotificationAdapter

[ブラウザ] GET /weekly_reports/:id
    ↓
WeeklyReportsController#show
    ↓
WeeklyReportPresenter.new(@report)                  ← Presenter
    ↓
WeeklySummaryCardComponent                          ← ViewComponent
    ↓ avg_weight → BodyWeight                       ← Value Object
    ↓ avg_body_fat → BodyFatRate                    ← Value Object
    ↓ total_cal → Calories                          ← Value Object
```
