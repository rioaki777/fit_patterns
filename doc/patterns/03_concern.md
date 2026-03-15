# 03. Concern（コンサーン）

## 概要

**複数のモデルで共有するスコープ・コールバック・メソッドをモジュールにまとめたもの**。
`ActiveSupport::Concern` を使い、`included` ブロックでモデルへの宣言的な追加を行います。

---

## 実装ファイル

`app/models/concerns/trackable.rb`

```ruby
module Trackable
  extend ActiveSupport::Concern

  included do
    # スコープ（クラスメソッドとして追加）
    scope :recently_modified, -> { order(updated_at: :desc).limit(10) }
    scope :created_this_week, -> { where(created_at: 1.week.ago..) }

    # コールバック（ライフサイクルフック）
    after_create  { Rails.logger.info "[Trackable] #{self.class.name} created: #{id}" }
    after_update  { Rails.logger.info "[Trackable] #{self.class.name} updated: #{id}" }
  end

  # インスタンスメソッド（includeしたモデルのインスタンスで使える）
  def age_in_days
    (Date.today - created_at.to_date).to_i
  end
end
```

---

## どこで使われるか

`app/models/weekly_report.rb` でインクルードしています:

```ruby
class WeeklyReport < ApplicationRecord
  include Trackable   # ← スコープ・コールバック・メソッドが全て追加される

  belongs_to :user
  # ...
end
```

---

## 追加されるもの

### スコープ

```ruby
# recently_modified: 最近更新された10件（レポート一覧で使用）
WeeklyReport.recently_modified
# => SELECT * FROM weekly_reports ORDER BY updated_at DESC LIMIT 10

# created_this_week: 今週作成されたもの
WeeklyReport.created_this_week
```

### コールバック

レポートが作成・更新されるたびに Rails ログへ出力:

```
[Trackable] WeeklyReport created: 1
[Trackable] WeeklyReport updated: 1
```

### インスタンスメソッド

```ruby
report = WeeklyReport.last
report.age_in_days  # => 3 (3日前に作成)
```

---

## コントローラーでの使用

```ruby
# app/controllers/weekly_reports_controller.rb
def index
  @reports = current_user.weekly_reports.recently_modified
  # ↑ Trackable の recently_modified スコープ
end
```

---

## コンソールで確認

```ruby
# スコープの動作確認
WeeklyReport.recently_modified
WeeklyReport.created_this_week

# インスタンスメソッド
WeeklyReport.last.age_in_days

# ログ出力確認（作成時にログが出る）
# create 時: "[Trackable] WeeklyReport created: 1" がログに出力される
```

---

## Concern のメリット

| 問題（モデルへの直書き） | 解決（Concern） |
|--------------------------|----------------|
| 同じスコープを複数モデルに重複定義 | Concern に一か所にまとめて `include` |
| スコープとコールバックがモデルに混在 | 責務ごとにモジュールを分割 |
| 共通ロジックの変更が多箇所に影響 | Concern だけ修正すればよい |

---

## 設計のポイント

- `extend ActiveSupport::Concern` で `included` ブロックが使えるようになる
- `included do ... end` 内に書いたものはインクルード先のクラスのコンテキストで実行される
- インスタンスメソッドは `included do` の外に書く
- Concern は「横断的関心事」を分離するもの。特定のモデルにしか使わないなら Concern にしない
