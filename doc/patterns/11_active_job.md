# 11. ActiveJob（非同期ジョブ）

## 概要

**時間のかかる処理を非同期で実行するための Rails 標準フレームワーク**。
レポート生成の通知（メール送信）を非同期化することで、ユーザーへのレスポンスを高速化します。

---

## 実装ファイル

`app/jobs/send_weekly_report_job.rb`

```ruby
class SendWeeklyReportJob < ApplicationJob
  queue_as :default

  def perform(weekly_report_id, channel)
    report  = WeeklyReport.find(weekly_report_id)
    adapter = NotificationAdapter.for(channel)
    adapter.deliver(report:)
    report.update!(notified_at: Time.current)

    ActiveSupport::Notifications.instrument("weekly_report.notified",
      report_id: report.id, channel:)
  end
end
```

---

## ジョブの引数設計

`perform_later(report.id, channel)` のように **オブジェクトではなく ID を渡す**のが重要です。

```ruby
# Workflow 内でのエンキュー
SendWeeklyReportJob.perform_later(report.id, @form.notification_channel)
# ↑ report オブジェクトではなく report.id を渡す

# Job の perform で再取得
def perform(weekly_report_id, channel)
  report = WeeklyReport.find(weekly_report_id)   # ← ジョブ実行時に最新データを取得
```

**理由**: ジョブがキューに入ってから実行されるまでに時間差があるため、
シリアライズ時のオブジェクトと実行時のオブジェクトが異なる可能性があります。

---

## 実行のタイミング

```
[同期: Workflow の中]
SendWeeklyReportJob.perform_later(report.id, channel)
→ キューにジョブを積む（即座に返る）

[非同期: バックグラウンドワーカー]
SendWeeklyReportJob#perform(report_id, channel)
→ NotificationAdapter.for(channel).deliver(report:)
→ report.update!(notified_at: Time.current)
→ Pub/Sub: instrument("weekly_report.notified")
```

---

## `notified_at` の更新

Job が正常に完了すると `notified_at` が更新されます:

```ruby
report.update!(notified_at: Time.current)
```

これにより Presenter で通知済みかどうかを表示できます:

```ruby
# app/presenters/weekly_report_presenter.rb
def notified?
  @report.notified_at.present?
end

def notification_label
  notified? ? "送信済み #{notified_at.strftime('%m/%d %H:%M')}" : "未送信"
end
```

---

## 開発環境での動作

開発環境では `config/environments/development.rb` に以下が設定されています（Rails デフォルト）:

```ruby
config.active_job.queue_adapter = :async  # インプロセスで非同期実行
```

本番環境では Sidekiq や GoodJob などのバックエンドが推奨されます。

---

## コンソールで確認

```ruby
# 通常の非同期エンキュー
SendWeeklyReportJob.perform_later(WeeklyReport.last.id, "email")

# 同期実行（テスト用）
SendWeeklyReportJob.perform_now(WeeklyReport.last.id, "slack")

# ジョブ実行後の確認
report = WeeklyReport.last
report.notified_at  # => "2024-01-14 09:30:00 UTC" (更新されている)
report.audit_logs.last.event  # => "weekly_report_updated"
```

---

## ActiveJob のメリット

| 問題（同期処理） | 解決（ActiveJob） |
|-----------------|-----------------|
| メール送信でレスポンスが遅い | 非同期化でユーザーへの応答を即座に返す |
| 通知失敗でトランザクションがロールバック | ジョブが失敗しても DB 保存は保持 |
| スケーリングが難しい | ワーカーを増やすだけで処理能力向上 |

---

## テスト例

```ruby
RSpec.describe SendWeeklyReportJob do
  include ActiveJob::TestHelper

  let(:report) { create(:weekly_report) }

  it "メール通知ジョブをエンキュー" do
    expect {
      SendWeeklyReportJob.perform_later(report.id, "email")
    }.to have_enqueued_job(SendWeeklyReportJob)
  end

  it "実行後に notified_at が更新される" do
    perform_enqueued_jobs do
      SendWeeklyReportJob.perform_later(report.id, "slack")
    end
    expect(report.reload.notified_at).not_to be_nil
  end
end
```
