# パターン全体マップ

fit_patterns で実装されている全デザインパターンの一覧です。

---

## パターンとリクエストフローの対応

```
POST /weekly_reports  ──────────────────────────────────────────────────
                                                                        │
WeeklyReportsController#create                                          │
│                                                                       │
├── WeeklyReportForm.new(params)              [06] Form Object         │
│       └── SafePeriodValidator               [02] Validator Object    │
│                                                                       │
├── WeeklyReportPolicy#create?               [05] Policy Object        │
│                                                                       │
└── GenerateWeeklyReportCommand.call(...)    [08] Command              │
        │                                                               │
        └── GenerateWeeklyReportWorkflow.call(...)  [09] Workflow      │
                │                                                       │
                ├── instrument("weekly_report.generate")  [12] Pub/Sub │
                │                                                       │
                ├── WeeklyReport::Generate.call(...)  [07] Service     │
                │       ├── WeightEntriesQuery.call(...)  [04] Query   │
                │       └── WorkoutsQuery.call(...)        [04] Query   │
                │                                                       │
                ├── WeeklyReport.create!(...)                           │
                │       └── after_commit: AuditLog.create!  [15] Cb   │
                │                                                       │
                └── SendWeeklyReportJob.perform_later(...)  [11] Job   │
                        │                                               │
                        └── NotificationAdapter.for(ch)  [10] Adapter  │
                                ├── MailNotificationAdapter             │
                                └── SlackNotificationAdapter            │
                                                                        │
GET /weekly_reports/:id  ───────────────────────────────────────────────
│
├── WeeklyReportPolicy#show?              [05] Policy Object
├── WeeklyReportPresenter.new(@report)   [13] Presenter
│       ├── avg_weight → BodyWeight       [01] Value Object
│       ├── avg_body_fat → BodyFatRate    [01] Value Object
│       └── total_cal → Calories          [01] Value Object
│
└── WeeklySummaryCardComponent           [14] ViewComponent

WeeklyReport (モデル)
└── include Trackable                    [03] Concern
```

---

## パターン一覧

| # | パターン | ファイル | 役割 |
|---|----------|----------|------|
| 01 | Value Object | `app/value_objects/` | 不変の値（体重・体脂肪・カロリー・期間） |
| 02 | Validator Object | `app/validators/safe_period_validator.rb` | 期間の複合バリデーション |
| 03 | Concern | `app/models/concerns/trackable.rb` | スコープ・コールバックの共通化 |
| 04 | Query Object | `app/queries/` | DB クエリのカプセル化 |
| 05 | Policy Object | `app/policies/weekly_report_policy.rb` | 認可ロジックの集約 |
| 06 | Form Object | `app/forms/weekly_report_form.rb` | フォーム入力のモデル化 |
| 07 | Service Object | `app/services/weekly_report/generate.rb` | 集計ビジネスロジック |
| 08 | Command | `app/commands/generate_weekly_report_command.rb` | 操作のカプセル化・Result 返却 |
| 09 | Workflow | `app/workflows/generate_weekly_report_workflow.rb` | トランザクション・オーケストレーション |
| 10 | Adapter | `app/adapters/` | 通知チャネルの差異を吸収 |
| 11 | ActiveJob | `app/jobs/send_weekly_report_job.rb` | 非同期処理 |
| 12 | Pub/Sub | `ActiveSupport::Notifications` in workflow/job | イベント駆動の疎結合 |
| 13 | Presenter | `app/presenters/weekly_report_presenter.rb` | ビュー表示ロジックの分離 |
| 14 | ViewComponent | `app/components/` | 再利用可能な UI コンポーネント |
| 15 | Callback | `WeeklyReport#write_audit_log` | DB 永続化後の副作用 |

---

## 各パターンの詳細

- [01 Value Object](01_value_object.md)
- [02 Validator Object](02_validator_object.md)
- [03 Concern](03_concern.md)
- [04 Query Object](04_query_object.md)
- [05 Policy Object](05_policy_object.md)
- [06 Form Object](06_form_object.md)
- [07 Service Object](07_service_object.md)
- [08 Command](08_command.md)
- [09 Workflow](09_workflow.md)
- [10 Adapter](10_adapter.md)
- [11 ActiveJob](11_active_job.md)
- [12 Pub/Sub](12_pub_sub.md)
- [13 Presenter](13_presenter.md)
- [14 ViewComponent](14_view_component.md)
- [15 Callback](15_callback.md)
