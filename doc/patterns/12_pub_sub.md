# 12. Pub/Sub（パブリッシュ・サブスクライブ）

## 概要

**イベントの発行（Publish）と購読（Subscribe）を分離する疎結合パターン**。
Rails では `ActiveSupport::Notifications` を使い、処理の計測やイベント駆動のログ記録を実装します。

---

## どこで使われるか

### Workflow での発行（`app/workflows/generate_weekly_report_workflow.rb`）

```ruby
def call
  ActiveSupport::Notifications.instrument("weekly_report.generate") do
    # トランザクション内の処理...
    # このブロックの実行時間が計測される
  end
end
```

### Job での発行（`app/jobs/send_weekly_report_job.rb`）

```ruby
def perform(weekly_report_id, channel)
  # ... 通知処理 ...

  ActiveSupport::Notifications.instrument("weekly_report.notified",
    report_id: report.id, channel: channel)
  # ↑ ペイロードを添付してイベントを発行
end
```

---

## イベント一覧

| イベント名 | 発行場所 | ペイロード |
|-----------|---------|-----------|
| `weekly_report.generate` | Workflow | なし（ブロックの実行時間のみ） |
| `weekly_report.notified` | Job | `{ report_id:, channel: }` |

---

## 購読側の実装例

`config/initializers/notifications.rb` などで購読を登録します
（このアプリでは initializer は未設定ですが、コンソールや spec で確認できます）:

```ruby
# ログ出力の購読例
ActiveSupport::Notifications.subscribe("weekly_report.generate") do |name, start, finish, id, payload|
  duration_ms = ((finish - start) * 1000).round
  Rails.logger.info "[Event] #{name} completed in #{duration_ms}ms"
end

# 通知完了イベントの購読例
ActiveSupport::Notifications.subscribe("weekly_report.notified") do |name, start, finish, id, payload|
  Rails.logger.info "[Notified] Report #{payload[:report_id]} via #{payload[:channel]}"
end
```

---

## `instrument` の動作

```ruby
ActiveSupport::Notifications.instrument("weekly_report.generate") do
  # ↑ ブロック開始時に "start" イベントが発行

  # ... 処理 ...

  # ↑ ブロック終了時に "finish" イベントが発行（例外でも）
end
```

購読者は以下の引数を受け取ります:

| 引数 | 内容 |
|------|------|
| `name` | イベント名 (`"weekly_report.generate"`) |
| `start` | 開始時刻 |
| `finish` | 終了時刻 |
| `id` | 一意なイベント ID |
| `payload` | 追加データの Hash |

---

## コンソールで確認

```ruby
# 購読を登録
subscription = ActiveSupport::Notifications.subscribe("weekly_report.generate") do |name, start, finish, id, payload|
  duration_ms = ((finish - start) * 1000).round
  puts "[Event] #{name} in #{duration_ms}ms"
end

# Workflow を実行 → イベントが発行される
user = User.first
form = WeeklyReportForm.new(
  period_start: Date.today - 14,
  period_end: Date.today - 8,
  notification_channel: "slack"
)
GenerateWeeklyReportWorkflow.call(user: user, form: form)
# => コンソールに "[Event] weekly_report.generate in 45ms" と表示

# 購読解除
ActiveSupport::Notifications.unsubscribe(subscription)
```

---

## Pub/Sub のメリット

| 問題（直接呼び出し） | 解決（Pub/Sub） |
|---------------------|----------------|
| ログ・計測をワークフローに書くと責務が混在 | 購読側に分離 |
| 新しい処理（メトリクス収集等）を追加するたびにワークフローを変更 | 購読を追加するだけ |
| テストで副作用の確認が難しい | イベントをキャプチャしてテストできる |

---

## テスト例

```ruby
RSpec.describe GenerateWeeklyReportWorkflow do
  it "generate イベントを発行する" do
    events = []
    subscription = ActiveSupport::Notifications.subscribe("weekly_report.generate") do |*args|
      events << args
    end

    # ... Workflow を実行 ...

    expect(events).not_to be_empty
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end
end
```
