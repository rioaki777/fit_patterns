# 14. ViewComponent（ビューコンポーネント）

## 概要

**再利用可能な UI コンポーネントをクラスとテンプレートのペアで実装するパターン**。
`view_component` gem を使い、Ruby クラスと ERB テンプレートをセットで管理します。
パーシャルよりテストしやすく、再利用性が高いです。

---

## 実装ファイル

### Ruby クラス（`app/components/weekly_summary_card_component.rb`）

```ruby
class WeeklySummaryCardComponent < ViewComponent::Base
  def initialize(presenter:)
    @presenter = presenter
  end
end
```

### ERB テンプレート（`app/components/weekly_summary_card_component.html.erb`）

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

## どこで使われるか

`app/views/weekly_reports/show.html.erb`:

```erb
<%= render WeeklySummaryCardComponent.new(presenter: @presenter) %>
```

コントローラーで `@presenter` を作成して渡します:

```ruby
# app/controllers/weekly_reports_controller.rb
def show
  @presenter = WeeklyReportPresenter.new(@report)
end
```

---

## パターンの連携

```
WeeklyReportsController#show
    ↓
@presenter = WeeklyReportPresenter.new(@report)   [Presenter]
    ↓
render WeeklySummaryCardComponent.new(presenter: @presenter)  [ViewComponent]
    ↓
weekly_summary_card_component.html.erb
    ├── @presenter.formatted_period     → "2024-01-08 〜 2024-01-14"
    ├── @presenter.formatted_weight     → "70.5 kg"    [Value Object]
    ├── @presenter.formatted_fat        → "20.0%"       [Value Object]
    ├── @presenter.formatted_calories   → "1500 kcal"   [Value Object]
    └── @presenter.notification_label   → "送信済み 01/14 09:30"
```

---

## テスト例

ViewComponent は Rails のビューシステムに依存せず、単体テストできます:

```ruby
# spec/components/weekly_summary_card_component_spec.rb
RSpec.describe WeeklySummaryCardComponent, type: :component do
  let(:report) do
    build(:weekly_report,
      period_start: Date.new(2024, 1, 8),
      period_end: Date.new(2024, 1, 14),
      avg_weight_g: 70_500,
      avg_body_fat_bp: 2_000,
      total_calories_kcal: 1_500,
      notified_at: Time.zone.parse("2024-01-14 09:30")
    )
  end
  let(:presenter) { WeeklyReportPresenter.new(report) }

  it "期間が表示される" do
    render_inline(described_class.new(presenter: presenter))
    expect(page).to have_text("2024-01-08 〜 2024-01-14")
  end

  it "体重が表示される" do
    render_inline(described_class.new(presenter: presenter))
    expect(page).to have_text("70.5 kg")
  end

  it "送信済みが表示される" do
    render_inline(described_class.new(presenter: presenter))
    expect(page).to have_text("送信済み")
  end
end
```

---

## ViewComponent のメリット

| 問題（パーシャル） | 解決（ViewComponent） |
|-------------------|----------------------|
| ローカル変数の型が不明 | コンストラクターで型を明示 |
| テストが integration test になる | `render_inline` で単体テスト |
| パーシャルへの依存関係が暗黙的 | 依存は `initialize` で明示 |
| ロジックをパーシャルに書けない | Ruby クラスにメソッドを定義できる |

---

## 設計のポイント

- `initialize(presenter:)` でキーワード引数を使い、依存を明示する
- テンプレートはクラスと同名の `.html.erb` ファイル（Zeitwerk が自動解決）
- コンポーネントのインスタンス変数 (`@presenter`) はテンプレートから直接参照できる
- 複雑なロジックはコンポーネントクラスにメソッドとして定義する
