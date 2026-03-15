# 10. Adapter（アダプター）

## 概要

**異なるインターフェースを持つ複数の実装を、共通のインターフェースで扱うパターン**。
ここでは「通知チャネル（メール/Slack）の違い」を吸収し、呼び出し元が実装を意識しないようにします。

---

## 実装ファイル

### 基底クラス（`app/adapters/notification_adapter.rb`）

```ruby
class NotificationAdapter
  # ファクトリメソッド: channel 名から適切なアダプターを返す
  def self.for(channel)
    case channel
    when "email" then MailNotificationAdapter.new
    when "slack"  then SlackNotificationAdapter.new
    else raise ArgumentError, "Unknown channel: #{channel}"
    end
  end

  # サブクラスが必ず実装すべきメソッド
  def deliver(report:)
    raise NotImplementedError, "#{self.class}#deliver is not implemented"
  end
end
```

### メール通知（`app/adapters/mail_notification_adapter.rb`）

```ruby
class MailNotificationAdapter < NotificationAdapter
  def deliver(report:)
    WeeklyReportMailer.report_ready(report).deliver_later
  end
end
```

### Slack 通知（`app/adapters/slack_notification_adapter.rb`）

```ruby
class SlackNotificationAdapter < NotificationAdapter
  def deliver(report:)
    Rails.logger.info "[Slack] Weekly report ready: #{report.id}"
    # 本番では Slack Webhook API を呼ぶ
  end
end
```

---

## クラス図

```
NotificationAdapter
├── .for(channel)           ← ファクトリメソッド
└── #deliver(report:)       ← テンプレートメソッド（抽象）
    │
    ├── MailNotificationAdapter
    │   └── #deliver → WeeklyReportMailer.report_ready(report).deliver_later
    │
    └── SlackNotificationAdapter
        └── #deliver → Rails.logger.info "[Slack] ..."
```

---

## どこで使われるか

`app/jobs/send_weekly_report_job.rb`:

```ruby
def perform(weekly_report_id, channel)
  report  = WeeklyReport.find(weekly_report_id)
  adapter = NotificationAdapter.for(channel)   # ← ファクトリメソッド
  adapter.deliver(report:)                      # ← 統一インターフェース

  report.update!(notified_at: Time.current)
  ActiveSupport::Notifications.instrument("weekly_report.notified",
    report_id: report.id, channel:)
end
```

---

## コンソールで確認

```ruby
report = WeeklyReport.last

# メール Adapter
mail_adapter = NotificationAdapter.for("email")
mail_adapter.class      # => MailNotificationAdapter
mail_adapter.deliver(report: report)
# => WeeklyReportMailer.report_ready(report).deliver_later を実行

# Slack Adapter
slack_adapter = NotificationAdapter.for("slack")
slack_adapter.class     # => SlackNotificationAdapter
slack_adapter.deliver(report: report)
# => ログ: "[Slack] Weekly report ready: 1"

# 不正なチャネル
NotificationAdapter.for("sms")
# => ArgumentError: Unknown channel: sms

# Job 経由での実行（非同期）
SendWeeklyReportJob.perform_now(report.id, "slack")
```

---

## Mailer との連携

`MailNotificationAdapter` が呼び出す Mailer:

```ruby
# app/mailers/weekly_report_mailer.rb
class WeeklyReportMailer < ApplicationMailer
  def report_ready(report)
    @report = report
    mail(to: report.user.email, subject: "週次レポートが生成されました")
  end
end
```

---

## Adapter パターンのメリット

| 問題（チャネルごとに条件分岐） | 解決（Adapter） |
|--------------------------------|----------------|
| Job に `if channel == "email"` が混在 | Job は `adapter.deliver(report:)` だけ呼ぶ |
| 新チャネル追加で Job を変更が必要 | 新 Adapter クラスを追加するだけ |
| テストが複雑 | 各 Adapter を独立してテストできる |

---

## 新しいチャネルの追加方法

1. `NotificationAdapter` を継承した新クラスを作成:

```ruby
# app/adapters/push_notification_adapter.rb
class PushNotificationAdapter < NotificationAdapter
  def deliver(report:)
    # プッシュ通知 API を呼ぶ
  end
end
```

2. `NotificationAdapter.for` にケースを追加:

```ruby
def self.for(channel)
  case channel
  when "email" then MailNotificationAdapter.new
  when "slack"  then SlackNotificationAdapter.new
  when "push"   then PushNotificationAdapter.new  # ← 追加
  else raise ArgumentError, "Unknown channel: #{channel}"
  end
end
```

Job・Workflow・Command は一切変更不要です。
