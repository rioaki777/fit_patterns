# 02. Validator Object（バリデーターオブジェクト）

## 概要

**複数フィールドにまたがる複合バリデーションをクラスに分離したもの**。
`ActiveModel::Validator` を継承し、`validates_with` で Form Object や Model に組み込みます。

---

## 実装ファイル

`app/validators/safe_period_validator.rb`

```ruby
class SafePeriodValidator < ActiveModel::Validator
  MAX_DAYS = 31

  def validate(record)
    start_date = record.period_start
    end_date   = record.period_end

    return if start_date.blank? || end_date.blank?

    if start_date > end_date
      record.errors.add(:period_start, "は終了日より前の日付を指定してください")
    end

    if end_date > Date.current
      record.errors.add(:period_end, "は未来日を指定できません")
    end

    if end_date - start_date >= MAX_DAYS
      record.errors.add(:base, "期間は#{MAX_DAYS}日以内にしてください")
    end
  end
end
```

---

## どこで使われるか

`app/forms/weekly_report_form.rb` の `validates_with` で組み込まれています:

```ruby
class WeeklyReportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :period_start, :date
  attribute :period_end,   :date
  attribute :notification_channel, :string, default: "email"

  validates :period_start, :period_end, :notification_channel, presence: true
  validates_with SafePeriodValidator   # ← Validator Object の呼び出し
end
```

`form.valid?` を呼ぶとき、`SafePeriodValidator#validate` が自動実行されます。

---

## バリデーション一覧

| チェック内容 | エラー対象 | メッセージ |
|------------|-----------|-----------|
| 開始日 > 終了日 | `period_start` | "は終了日より前の日付を指定してください" |
| 終了日が未来日 | `period_end` | "は未来日を指定できません" |
| 期間が31日以上 | `base` | "期間は31日以内にしてください" |

---

## コンソールで確認

```ruby
# 正常ケース
form = WeeklyReportForm.new(
  period_start: Date.today - 7,
  period_end: Date.today,
  notification_channel: "email"
)
form.valid?  # => true

# 開始日 > 終了日
form = WeeklyReportForm.new(
  period_start: Date.today,
  period_end: Date.today - 1,
  notification_channel: "email"
)
form.valid?
form.errors.full_messages
# => ["Period start は終了日より前の日付を指定してください"]

# 未来日
form = WeeklyReportForm.new(
  period_start: Date.today,
  period_end: Date.today + 1,
  notification_channel: "email"
)
form.valid?
form.errors.full_messages
# => ["Period end は未来日を指定できません"]

# 32日間
form = WeeklyReportForm.new(
  period_start: Date.today - 32,
  period_end: Date.today,
  notification_channel: "email"
)
form.valid?
form.errors.full_messages
# => ["期間は31日以内にしてください"]
```

---

## Validator Object のメリット

| 問題（モデル内バリデーション） | 解決（Validator Object） |
|------------------------------|------------------------|
| 複数フィールドのロジックが一か所に混在 | クラスに分離して責務を明確化 |
| 複数モデルで同じバリデーションを再利用できない | `validates_with SafePeriodValidator` で再利用可能 |
| テストが書きにくい | バリデーターを単体テストできる |

---

## テスト例（`spec/validators/safe_period_validator_spec.rb`）

```ruby
RSpec.describe SafePeriodValidator do
  subject(:form) do
    WeeklyReportForm.new(
      period_start: start_date,
      period_end: end_date,
      notification_channel: "email"
    )
  end

  context "終了日が開始日より前の場合" do
    let(:start_date) { Date.today }
    let(:end_date)   { Date.today - 1 }

    it "エラーになる" do
      expect(form).not_to be_valid
      expect(form.errors[:period_start]).to be_present
    end
  end
end
```
