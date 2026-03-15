# 04. Query Object（クエリオブジェクト）

## 概要

**DB クエリのロジックをクラスに分離したもの**。
複雑なクエリをモデルやコントローラーに書かず、専用クラスにカプセル化します。
`.call(user:, period:)` のインターフェースで ActiveRecord リレーションを返します。

---

## 実装ファイル

### `app/queries/weight_entries_query.rb`

```ruby
class WeightEntriesQuery
  def self.call(user:, period:)
    new(user:, period:).call
  end

  def initialize(user:, period:)
    @user = user
    @period = period
  end

  def call
    WeightEntry.where(user: @user)
               .between_dates(@period.start_date, @period.end_date)
               .order(recorded_on: :asc)
  end
end
```

### `app/queries/workouts_query.rb`

```ruby
class WorkoutsQuery
  def self.call(user:, period:)
    new(user:, period:).call
  end

  def initialize(user:, period:)
    @user = user
    @period = period
  end

  def call
    Workout.where(user: @user)
           .between_dates(@period.start_date, @period.end_date)
           .order(recorded_on: :asc)
  end
end
```

---

## どこで使われるか

`app/services/weekly_report/generate.rb` から呼び出されます:

```ruby
class WeeklyReport::Generate
  def call
    weight_entries = WeightEntriesQuery.call(user: @user, period: @period)
    workouts       = WorkoutsQuery.call(user: @user, period: @period)

    {
      avg_weight_g:        calc_avg_weight(weight_entries),
      avg_body_fat_bp:     calc_avg_body_fat(weight_entries),
      total_calories_kcal: workouts.sum(:calories_kcal),
      total_workout_min:   workouts.sum(:duration_min)
    }
  end
end
```

---

## `between_dates` スコープ

Query Object が依存する `between_dates` スコープはモデルに定義されています:

```ruby
# app/models/weight_entry.rb
scope :between_dates, ->(from, to) { where(recorded_on: from..to) }

# app/models/workout.rb
scope :between_dates, ->(from, to) { where(recorded_on: from..to) }
```

---

## コンソールで確認

```ruby
user = User.first
period = Period.new(start_date: Date.today - 7, end_date: Date.today)

# Query Object 経由で取得（Service Object で使われる方法と同じ）
entries = WeightEntriesQuery.call(user: user, period: period)
entries.count
entries.first

workouts = WorkoutsQuery.call(user: user, period: period)
workouts.sum(:calories_kcal)
workouts.sum(:duration_min)

# 返り値は ActiveRecord::Relation なので通常通り操作可能
entries.where("weight_g > ?", 70_000).count
```

---

## 生成される SQL

```sql
-- WeightEntriesQuery
SELECT "weight_entries".*
FROM "weight_entries"
WHERE "weight_entries"."user_id" = 1
  AND "weight_entries"."recorded_on" BETWEEN '2024-01-08' AND '2024-01-14'
ORDER BY "weight_entries"."recorded_on" ASC

-- WorkoutsQuery (sum)
SELECT SUM("workouts"."calories_kcal")
FROM "workouts"
WHERE "workouts"."user_id" = 1
  AND "workouts"."recorded_on" BETWEEN '2024-01-08' AND '2024-01-14'
```

---

## Query Object のメリット

| 問題（モデル/コントローラー内クエリ） | 解決（Query Object） |
|--------------------------------------|---------------------|
| 複雑なクエリがあちこちに散在 | Query Object に集約して1か所で管理 |
| テストが書きにくい | Query Object を単体テストできる |
| 再利用できない | `.call(user:, period:)` で他からも呼べる |
| モデルにスコープが増えすぎる | Query Object が責務を持つ |

---

## テスト例

```ruby
RSpec.describe WeightEntriesQuery do
  let(:user)   { create(:user) }
  let(:period) { Period.new(start_date: Date.today - 7, end_date: Date.today) }

  before do
    create(:weight_entry, user: user, recorded_on: Date.today - 3)
    create(:weight_entry, user: user, recorded_on: Date.today - 30)  # 範囲外
    create(:weight_entry, recorded_on: Date.today - 3)               # 別ユーザー
  end

  it "指定期間・ユーザーの体重記録のみ返す" do
    result = described_class.call(user: user, period: period)
    expect(result.count).to eq(1)
  end
end
```
