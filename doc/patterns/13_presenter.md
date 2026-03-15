# 13. Presenter（プレゼンター）

## 概要

**ビュー表示用のロジックをモデルから分離したクラス**。
モデルの生データを「表示に適した形式」に変換します。
ビューに `if` / `strftime` / 文字列連結が散らばるのを防ぎます。

---

## 実装ファイル

`app/presenters/weekly_report_presenter.rb`

```ruby
class WeeklyReportPresenter
  delegate :id, :user, :period_start, :period_end, :notified_at, to: :@report

  def initialize(report)
    @report = report
  end

  def formatted_period
    "#{period_start} 〜 #{period_end}"
  end

  def formatted_weight
    @report.avg_weight&.formatted || "データなし"
    # BodyWeight#formatted → "70.0 kg"
  end

  def formatted_fat
    @report.avg_body_fat&.formatted || "データなし"
    # BodyFatRate#formatted → "20.0%"
  end

  def formatted_calories
    @report.total_cal&.formatted || "データなし"
    # Calories#formatted → "1500 kcal"
  end

  def notified?
    @report.notified_at.present?
  end

  def notification_label
    notified? ? "送信済み #{notified_at.strftime('%m/%d %H:%M')}" : "未送信"
  end
end
```

---

## どこで使われるか

### コントローラー（`app/controllers/weekly_reports_controller.rb`）

```ruby
def show
  @presenter = WeeklyReportPresenter.new(@report)
end
```

### ビュー（`app/views/weekly_reports/show.html.erb`）

```erb
<%= render WeeklySummaryCardComponent.new(presenter: @presenter) %>

<p>期間: <%= @presenter.formatted_period %></p>
<p>体重: <%= @presenter.formatted_weight %></p>
<p>通知: <%= @presenter.notification_label %></p>
```

### ViewComponent（`app/components/weekly_summary_card_component.html.erb`）

```erb
<div class="weekly-summary-card">
  <h3><%= @presenter.formatted_period %></h3>
  <dl>
    <dt>平均体重</dt><dd><%= @presenter.formatted_weight %></dd>
    <dt>平均体脂肪率</dt><dd><%= @presenter.formatted_fat %></dd>
    <dt>総カロリー</dt><dd><%= @presenter.formatted_calories %></dd>
    <dt>通知</dt><dd><%= @presenter.notification_label %></dd>
  </dl>
</div>
```

---

## Presenter のメソッド一覧

| メソッド | 戻り値例 | 変換内容 |
|----------|---------|---------|
| `formatted_period` | `"2024-01-08 〜 2024-01-14"` | 日付を文字列に |
| `formatted_weight` | `"70.5 kg"` | Value Object → 文字列（nil → "データなし"） |
| `formatted_fat` | `"20.0%"` | Value Object → 文字列（nil → "データなし"） |
| `formatted_calories` | `"1500 kcal"` | Value Object → 文字列（nil → "データなし"） |
| `notified?` | `true` / `false` | notified_at の有無 |
| `notification_label` | `"送信済み 01/14 09:30"` / `"未送信"` | 条件に応じた文字列 |

---

## `delegate` の活用

```ruby
delegate :id, :user, :period_start, :period_end, :notified_at, to: :@report
```

これにより `presenter.period_start` が `@report.period_start` に委譲されます。
ビューから直接 Presenter だけを参照すれば OK です。

---

## コンソールで確認

```ruby
report = WeeklyReport.last
presenter = WeeklyReportPresenter.new(report)

presenter.formatted_period    # => "2024-01-08 〜 2024-01-14"
presenter.formatted_weight    # => "70.5 kg" (データなし → "データなし")
presenter.formatted_fat       # => "20.0%"
presenter.formatted_calories  # => "1500 kcal"
presenter.notified?           # => false (通知前) / true (通知後)
presenter.notification_label  # => "未送信" / "送信済み 01/14 09:30"
```

---

## Presenter のメリット

| 問題（ビューにロジック） | 解決（Presenter） |
|--------------------------|-----------------|
| ERB に `if`・`strftime`・単位変換が散在 | Presenter メソッドに集約 |
| 同じフォーマットを複数ビューで重複記述 | Presenter を共有 |
| ビューのテストが書きにくい | Presenter を単体テストできる |
| モデルに表示ロジックが増えて肥大化 | 責務を分離 |

---

## テスト例

```ruby
RSpec.describe WeeklyReportPresenter do
  let(:report) { build(:weekly_report, avg_weight_g: 70_500, notified_at: nil) }
  let(:presenter) { described_class.new(report) }

  describe "#formatted_weight" do
    it "kg 表示に変換する" do
      expect(presenter.formatted_weight).to eq("70.5 kg")
    end
  end

  describe "#notification_label" do
    it "未通知の場合は「未送信」を返す" do
      expect(presenter.notification_label).to eq("未送信")
    end

    context "通知済みの場合" do
      let(:report) { build(:weekly_report, notified_at: Time.zone.parse("2024-01-14 09:30")) }

      it "送信日時を返す" do
        expect(presenter.notification_label).to eq("送信済み 01/14 09:30")
      end
    end
  end
end
```
