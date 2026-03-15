# 06. Form Object（フォームオブジェクト）

## 概要

**フォームからの入力を受け取り、バリデーションを行う専用クラス**。
`ActiveModel::Model` と `ActiveModel::Attributes` を include することで、
ActiveRecord モデルと同じ `valid?` / `errors` インターフェースを持ちます。

---

## 実装ファイル

`app/forms/weekly_report_form.rb`

```ruby
class WeeklyReportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :period_start, :date    # 文字列を Date に自動変換
  attribute :period_end,   :date
  attribute :notification_channel, :string, default: "email"

  validates :period_start, :period_end, :notification_channel, presence: true
  validates_with SafePeriodValidator   # Validator Object を組み込む

  def period
    Period.new(start_date: period_start, end_date: period_end)
    # フォームの属性 → Value Object への変換
  end
end
```

---

## どこで使われるか

### コントローラー（`app/controllers/weekly_reports_controller.rb`）

```ruby
def new
  @form = WeeklyReportForm.new(
    period_start: 1.week.ago.to_date,
    period_end: Date.today
  )
end

def create
  @form = WeeklyReportForm.new(weekly_report_params)

  # ...
  result = GenerateWeeklyReportCommand.call(user: current_user, form: @form)
  # ↑ user は別で渡す（Form Object に current_user を持たせない）

  if result.success?
    redirect_to weekly_report_path(result.report), notice: "レポートを生成しました"
  else
    render :new, status: :unprocessable_entity
  end
end

private

def weekly_report_params
  params.require(:weekly_report_form).permit(:period_start, :period_end, :notification_channel)
end
```

### Command（`app/commands/generate_weekly_report_command.rb`）

```ruby
def call
  unless @form.valid?   # ← Form Object のバリデーション
    return Result.new(success?: false, report: nil, errors: @form.errors)
  end

  report = GenerateWeeklyReportWorkflow.call(user: @user, form: @form)
  Result.new(success?: true, report:, errors: nil)
end
```

### ビュー（`app/views/weekly_reports/new.html.erb`）

```erb
<%= form_with model: @form, url: weekly_reports_path do |f| %>
  <%= f.date_field :period_start %>
  <%= f.date_field :period_end %>
  <%= f.select :notification_channel, [["メール", "email"], ["Slack", "slack"]] %>
  <%= f.submit "生成" %>
<% end %>
```

---

## Form Object の属性マッピング

| フォームパラメータ | 型変換 | Form Object 属性 |
|------------------|--------|-----------------|
| `"2024-01-08"` (文字列) | → Date | `period_start` |
| `"2024-01-14"` (文字列) | → Date | `period_end` |
| `"email"` (文字列) | そのまま | `notification_channel` |

---

## バリデーションの流れ

```
WeeklyReportForm#valid?
  ↓
1. validates :period_start, presence: true    → nil チェック
2. validates :period_end, presence: true      → nil チェック
3. validates :notification_channel, presence: true
4. validates_with SafePeriodValidator         → 複合バリデーション
   ├── start_date > end_date?
   ├── end_date が未来?
   └── end_date - start_date >= 31?
```

---

## コンソールで確認

```ruby
# 正常ケース
form = WeeklyReportForm.new(
  period_start: "2024-01-08",    # 文字列でも Date に変換される
  period_end: "2024-01-14",
  notification_channel: "email"
)
form.valid?          # => true
form.period          # => #<Period start_date=2024-01-08 end_date=2024-01-14>
form.period.days     # => 7

# エラーケース
form = WeeklyReportForm.new(
  period_start: Date.today,
  period_end: Date.today - 1,
  notification_channel: "email"
)
form.valid?                   # => false
form.errors.full_messages     # => ["Period start は終了日より前..."]
form.errors[:period_start]    # => ["は終了日より前の日付を指定してください"]
```

---

## Form Object のメリット

| 問題（ActiveRecord モデルに直接フォーム） | 解決（Form Object） |
|------------------------------------------|-------------------|
| DB のカラムと異なる入力形式を扱えない | 属性を自由に定義できる |
| 複数モデルにまたがるフォームを扱えない | Form Object が束ねる |
| `current_user` をフォームが知ってしまう | user は別で渡す設計にできる |
| バリデーション違いで複数バリエーションが必要 | Form Object ごとに異なるバリデーション |
