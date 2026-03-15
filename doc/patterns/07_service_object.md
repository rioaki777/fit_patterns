# 07. Service Object（サービスオブジェクト）

## 概要

**単一のビジネスロジックを実行するクラス**。
モデルにもコントローラーにも属さない「集計・計算」などのドメインロジックを担います。
`.call(user:, period:)` の単一エントリーポイントを持ちます。

---

## 実装ファイル

`app/services/weekly_report/generate.rb`

```ruby
class WeeklyReport::Generate
  def self.call(user:, period:)
    new(user:, period:).call
  end

  def initialize(user:, period:)
    @user = user
    @period = period
  end

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

  private

  def calc_avg_weight(entries)
    return nil if entries.empty?
    (entries.sum(:weight_g) / entries.count.to_f).round
  end

  def calc_avg_body_fat(entries)
    with_fat = entries.where.not(body_fat_bp: nil)
    return nil if with_fat.empty?
    (with_fat.sum(:body_fat_bp) / with_fat.count.to_f).round
  end
end
```

---

## 何を計算するか

| 戻り値キー | 計算内容 | nil になる条件 |
|-----------|---------|--------------|
| `avg_weight_g` | 期間内の体重エントリーの平均（グラム） | エントリーが0件 |
| `avg_body_fat_bp` | 体脂肪率が入力されているエントリーの平均（bp） | 体脂肪率入力が0件 |
| `total_calories_kcal` | 期間内のワークアウトの合計カロリー | ワークアウトが0件なら0 |
| `total_workout_min` | 期間内のワークアウトの合計時間 | ワークアウトが0件なら0 |

---

## どこで使われるか

`app/workflows/generate_weekly_report_workflow.rb`:

```ruby
def call
  ActiveRecord::Base.transaction do
    stats  = WeeklyReport::Generate.call(user: @user, period: @form.period)
    # ↑ Service Object が集計 → Hash を返す

    report = WeeklyReport.create!(
      user: @user,
      **stats,             # Hash をスプレッドして渡す
      period_start: @form.period.start_date,
      period_end:   @form.period.end_date
    )
    # ...
  end
end
```

---

## コンソールで確認

```ruby
user = User.first
period = Period.new(start_date: Date.today - 7, end_date: Date.today)

# Service Object 単体実行
stats = WeeklyReport::Generate.call(user: user, period: period)
# => {
#      avg_weight_g: 70500,
#      avg_body_fat_bp: 2000,
#      total_calories_kcal: 1500,
#      total_workout_min: 180
#    }

# データがない場合
empty_period = Period.new(start_date: Date.today - 100, end_date: Date.today - 90)
stats = WeeklyReport::Generate.call(user: user, period: empty_period)
# => { avg_weight_g: nil, avg_body_fat_bp: nil, total_calories_kcal: 0, total_workout_min: 0 }
```

---

## 依存関係

```
WeeklyReport::Generate
  ├── WeightEntriesQuery    (Query Object)
  │     └── WeightEntry     (ActiveRecord Model)
  └── WorkoutsQuery         (Query Object)
        └── Workout          (ActiveRecord Model)
```

---

## Service Object のメリット

| 問題（モデル内ロジック） | 解決（Service Object） |
|--------------------------|----------------------|
| `WeeklyReport` モデルが肥大化 | Generate クラスに集計ロジックを分離 |
| モデルのテストが遅い（DB 必要） | Service Object をより小さく単体テスト |
| 集計ロジックの再利用が難しい | `WeeklyReport::Generate.call(...)` で呼び出し可能 |

---

## テスト例

```ruby
RSpec.describe WeeklyReport::Generate do
  let(:user)   { create(:user) }
  let(:period) { Period.new(start_date: Date.today - 7, end_date: Date.today) }

  context "データがある場合" do
    before do
      create(:weight_entry, user: user, recorded_on: Date.today - 3,
             weight_g: 70_000, body_fat_bp: 2_000)
      create(:workout, user: user, recorded_on: Date.today - 3,
             calories_kcal: 300, duration_min: 30)
    end

    it "集計値を返す" do
      result = described_class.call(user: user, period: period)
      expect(result[:avg_weight_g]).to eq(70_000)
      expect(result[:total_calories_kcal]).to eq(300)
    end
  end

  context "データがない場合" do
    it "nil / 0 を返す" do
      result = described_class.call(user: user, period: period)
      expect(result[:avg_weight_g]).to be_nil
      expect(result[:total_calories_kcal]).to eq(0)
    end
  end
end
```
