# 03. データ入力（体重・ワークアウトの記録）

週次レポートを生成するためには、事前に体重・ワークアウトのデータを入力する必要があります。
レポート対象期間内にデータがない場合、集計値は `nil` になります。

---

## 体重の記録

### 画面操作

1. http://localhost:3000/weight_entries/new にアクセス
2. フォームに入力して「保存」

| フィールド | 入力例 | 備考 |
|------------|--------|------|
| 記録日 | `2024-01-15` | 未来日は不可 |
| 体重 (g) | `70000` | 70.0 kg = 70,000 g |
| 体脂肪率 (bp) | `2000` | 20.0% = 2,000 bp (basis points) |
| メモ | `朝食前` | 任意 |

> **単位について**
> - 体重はグラム単位で保存（`weight_g`）
> - 体脂肪率は basis points 単位で保存（`body_fat_bp`）: 1% = 100bp
> - 表示時は Value Object が変換します（`BodyWeight#to_kg`、`BodyFatRate#to_percent`）

### バリデーション

| 条件 | エラーメッセージ |
|------|-----------------|
| 記録日が未来 | "は未来日を指定できません" |
| 体重が範囲外 (20,000g〜300,000g) | numericality エラー |
| 同じ日付が重複 | uniqueness エラー |

### Rails コンソールでの一括作成（テストデータ）

```ruby
user = User.first

# 1週間分の体重データを作成
7.times do |i|
  date = Date.today - 7 + i
  WeightEntry.create!(
    user: user,
    recorded_on: date,
    weight_g: rand(68_000..72_000),
    body_fat_bp: rand(1_800..2_200)
  )
end
```

---

## ワークアウトの記録

### 画面操作

1. http://localhost:3000/workouts/new にアクセス
2. フォームに入力して「保存」

| フィールド | 入力例 | 備考 |
|------------|--------|------|
| 記録日 | `2024-01-15` | 未来日は不可 |
| 種目 (kind) | `running` | 必須、最大50文字 |
| 時間 (min) | `30` | 任意、0〜1440分 |
| カロリー (kcal) | `300` | 任意、0〜20,000 |
| 強度 | `7` | 任意、1〜10 |
| メモ | `ジョギング` | 任意 |

### Rails コンソールでの一括作成（テストデータ）

```ruby
user = User.first
kinds = ["running", "cycling", "strength", "yoga"]

7.times do |i|
  date = Date.today - 7 + i
  Workout.create!(
    user: user,
    recorded_on: date,
    kind: kinds.sample,
    duration_min: rand(20..60),
    calories_kcal: rand(150..500),
    intensity: rand(5..9)
  )
end
```

---

## データ確認

### 一覧画面

- 体重記録: http://localhost:3000/weight_entries
- ワークアウト: http://localhost:3000/workouts

### Rails コンソール

```ruby
user = User.first

# 体重記録の確認
user.weight_entries.recent.first(3)

# ワークアウトの確認
user.workouts.recent.first(3)

# Query Object を使った期間絞り込み（パターン動作確認）
period = Period.new(start_date: Date.today - 7, end_date: Date.today)
WeightEntriesQuery.call(user: user, period: period)
WorkoutsQuery.call(user: user, period: period)
```

---

## 関連するパターン

データ取得時には **Query Object** が使われます:

```ruby
# app/queries/weight_entries_query.rb
class WeightEntriesQuery
  def call
    WeightEntry.where(user: @user)
               .between_dates(@period.start_date, @period.end_date)
               .order(recorded_on: :asc)
  end
end
```

詳細: [patterns/04_query_object.md](patterns/04_query_object.md)

---

次のステップ: [04_report_generation.md](04_report_generation.md)
