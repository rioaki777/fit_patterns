# 01. Value Object（値オブジェクト）

## 概要

**不変（immutable）な値を型として表現するオブジェクト**。
プリミティブな数値に意味と振る舞いを持たせます。

---

## 実装ファイル

| クラス | ファイル | 表す概念 |
|--------|----------|----------|
| `Period` | `app/value_objects/period.rb` | 期間（開始日〜終了日） |
| `BodyWeight` | `app/value_objects/body_weight.rb` | 体重（グラム単位） |
| `BodyFatRate` | `app/value_objects/body_fat_rate.rb` | 体脂肪率（basis points 単位） |
| `Calories` | `app/value_objects/calories.rb` | カロリー（kcal 単位） |

---

## コード例

```ruby
# app/value_objects/body_weight.rb
class BodyWeight
  attr_reader :grams

  def initialize(grams)
    @grams = grams
    freeze   # ← 不変にする重要ポイント
  end

  def to_kg
    grams / 1000.0
  end

  def formatted
    "#{to_kg} kg"
  end

  def ==(other)
    other.is_a?(BodyWeight) && grams == other.grams
  end
end
```

```ruby
# app/value_objects/period.rb
class Period
  attr_reader :start_date, :end_date

  def initialize(start_date:, end_date:)
    @start_date = start_date
    @end_date = end_date
    freeze
  end

  def days
    (end_date - start_date).to_i + 1
  end

  def covers?(date)
    to_range.cover?(date)
  end

  def to_range
    start_date..end_date
  end
end
```

---

## どこで使われるか

### モデルでの使用（`app/models/weekly_report.rb`）

```ruby
class WeeklyReport < ApplicationRecord
  def avg_weight
    BodyWeight.new(avg_weight_g) if avg_weight_g   # DB の整数 → Value Object
  end

  def avg_body_fat
    BodyFatRate.new(avg_body_fat_bp) if avg_body_fat_bp
  end

  def total_cal
    Calories.new(total_calories_kcal) if total_calories_kcal
  end
end
```

### Presenter での使用（`app/presenters/weekly_report_presenter.rb`）

```ruby
def formatted_weight
  @report.avg_weight&.formatted || "データなし"
  # BodyWeight#formatted → "70.0 kg"
end

def formatted_fat
  @report.avg_body_fat&.formatted || "データなし"
  # BodyFatRate#formatted → "20.0%"
end
```

### Form Object での使用（`app/forms/weekly_report_form.rb`）

```ruby
def period
  Period.new(start_date: period_start, end_date: period_end)
  # フォームの日付文字列 → Period Value Object
end
```

---

## コンソールで確認

```ruby
# 体重
w = BodyWeight.new(70_500)
w.to_kg      # => 70.5
w.formatted  # => "70.5 kg"
w.frozen?    # => true (不変であることを確認)

# 体脂肪率
f = BodyFatRate.new(2_000)
f.to_percent  # => 20.0
f.formatted   # => "20.0%"

# カロリー
c1 = Calories.new(300)
c2 = Calories.new(200)
(c1 + c2).kcal     # => 500
(c1 + c2).formatted # => "500 kcal"

# 期間
p = Period.new(start_date: Date.today - 7, end_date: Date.today)
p.days             # => 8
p.covers?(Date.today - 3)  # => true
p.to_range         # => (2024-01-07..2024-01-14)

# 同値比較
BodyWeight.new(70_000) == BodyWeight.new(70_000)  # => true
BodyWeight.new(70_000) == BodyWeight.new(71_000)  # => false
```

---

## Value Object のメリット

| 問題（プリミティブ値） | 解決（Value Object） |
|----------------------|---------------------|
| `70000` が何を意味するか不明 | `BodyWeight.new(70000)` で意味が明確 |
| g→kg 変換ロジックが散在 | `body_weight.to_kg` に集約 |
| 表示フォーマットがビューに書かれる | `body_weight.formatted` に集約 |
| `nil` チェックが必要な箇所が多い | モデルで `BodyWeight.new(...)` が nil を吸収 |

---

## 設計のポイント

1. **`freeze` を `initialize` の最後に必ず呼ぶ** — 後からの変更を禁止
2. **`==` を定義する** — 同じ値なら同じオブジェクトとして扱えるように
3. **DB には整数で保存** — Value Object は表示・計算のラッパー
4. **`nil` を Value Object にしない** — nil は nil のまま、モデルで `if avg_weight_g` を使う
