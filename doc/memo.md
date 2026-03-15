これは多くのデザインパターンを“触れる”ことを目的にしたRailsアプリ。学習効率が最大になるように設計する。（※実務最適ではなく、“意図的にパターンを踏める教材設計”寄り）

# 1 題材ドメイン

ユーザーが体重・体脂肪・運動・食事を記録し、週次レポートを作り、通知するアプリ。

- Deviseでログイン
- 記録（CRUD）
- 集計（Query）
- レポート生成（Service/Command）
- 外部連携（Adapter）
- 権限（Policy）
- 表示（Presenter/ViewComponent）
- 非同期（ActiveJob）
- 計測（Notifications）
- 値の表現（Value Object）
- ルール（Validator）
- 手順（Workflow/Interactor）
- 横断（Concern）
- コールバック（Callback）


# 2 “全部踏める”ユースケース設計（1つの流れに全部を載せる）

ユースケース：週次レポート生成 → 通知 → 保存 → 監査ログ

1. ユーザーが「今週のレポートを作る」を押す（Controller）
2. Policyで実行可否
3. Form Objectで入力（期間・目標・送信先）
4. Workflow/Interactorが処理手順をオーケストレーション

    - 記録の取得（Query Object）
    - 指標計算（Value Object）
    - レポート生成（Service / Command）
    - 保存（ActiveRecord）
    - 通知（Notification layer）
    - 非同期化（ActiveJob）

5. 各ステップで ActiveSupport::Notifications を発火して計測
6. 重要イベントは Callback（after_commit）で監査ログを積む
7. 表示は Presenter / ViewComponent が担当

この1ユースケースを完成させるだけで、だいたい全部触れる。

# 3 各パターンを“何で試すか”の対応表

- MVC：通常のCRUD（WeightEntry/Workout）
- Active Record：WeightEntry, Workout, WeeklyReport, AuditLog
- Callback：WeeklyReport の after_commit :write_audit_log
- Concern：Trackable（作成者、変更履歴、共通スコープなど）
- Policy Object：WeeklyReportPolicy（本人のみ、管理者のみなど）
- Form Object：WeeklyReportForm（期間 + オプション + 複数モデル更新も可能に）
- Query Object：WeightEntriesQuery, WorkoutsQuery（期間/ユーザー/種目で検索）
- Value Object：Period, BodyWeight, BodyFatRate, Calories（単位や丸めルールを隠蔽）
- Validator Object：SafePeriodValidator（期間が長すぎない、未来日NGなど）
- Service Object：WeeklyReport::Generate（レポートの中身生成）
- Command：GenerateWeeklyReportCommand.call(form)（実行単位を“命令”として扱う）
- Workflow/Interactor：GenerateWeeklyReportWorkflow（ステップ分割、失敗時ロールバック方針）
- Adapter：NotificationAdapter（メール/Slack/Push差し替え）、MetricsAdapter（StatsD等）
- Pub/Sub：ActiveSupport::Notifications.instrument("weekly_report.generate")
- Presenter/Decorator：WeeklyReportPresenter（表示整形）
- ViewComponent：WeeklySummaryCardComponent（UI部品 + テスト）
- ActiveJob：SendWeeklyReportJob（通知送信、重い集計）

# 4 “全部試せる”ためのテスト方針（ここまでやると学習が完成する）

- Model spec：ValueObject / Validator / Query
- Service/Command spec：入力→出力、失敗時
- Workflow spec：ステップ順・途中失敗時の挙動
- Job spec：enqueue/perform、Adapterの呼び出し
- Policy spec：権限パターン
- ViewComponent spec：表示の分岐、フォーマット
- Notifications spec：instrumentが呼ばれること（最低限）
