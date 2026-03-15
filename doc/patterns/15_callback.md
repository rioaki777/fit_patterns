# 15. Callback（コールバック）

## 概要

**モデルのライフサイクルイベント（保存・更新・削除）に自動実行される処理**。
`after_commit` を使い、DB トランザクションが確定した後に監査ログを記録します。

---

## 実装ファイル

### WeeklyReport モデル（`app/models/weekly_report.rb`）

```ruby
class WeeklyReport < ApplicationRecord
  include Trackable   # Concern も after_create / after_update を追加している

  # ...

  after_commit :write_audit_log, on: [:create, :update]
  # ↑ DB コミット完了後に実行（トランザクションロールバック時は実行されない）

  private

  def write_audit_log
    AuditLog.create!(
      auditable: self,                         # ポリモーフィック関連
      event: "weekly_report_#{saved_change_to_id? ? 'created' : 'updated'}",
      user_id: user_id,
      payload: { period_start:, period_end:, notified_at: }
    )
  end
end
```

---

## AuditLog モデル（`app/models/audit_log.rb`）

```ruby
class AuditLog < ApplicationRecord
  belongs_to :auditable, polymorphic: true
  # auditable_type: "WeeklyReport"
  # auditable_id: 1

  validates :event, presence: true

  scope :for, ->(record) { where(auditable: record) }
end
```

---

## テーブル構造

```sql
CREATE TABLE audit_logs (
  id             BIGSERIAL PRIMARY KEY,
  auditable_type VARCHAR NOT NULL,   -- "WeeklyReport"
  auditable_id   BIGINT  NOT NULL,   -- レポートの ID
  event          VARCHAR NOT NULL,   -- "weekly_report_created" | "weekly_report_updated"
  user_id        INTEGER,
  payload        JSONB,              -- { period_start, period_end, notified_at }
  created_at     TIMESTAMP NOT NULL,
  updated_at     TIMESTAMP NOT NULL
);
```

---

## コールバックチェーン

`WeeklyReport` では複数のコールバックが連鎖します:

```
WeeklyReport.create!(...)
    │
    ├── [Trackable Concern] after_create
    │   → Rails.logger.info "[Trackable] WeeklyReport created: 1"
    │
    └── [after_commit] :write_audit_log
        → AuditLog.create!(event: "weekly_report_created", ...)
        → 監査ログが DB に記録される
```

`after_commit` vs `after_create` の違い:

| | `after_create` | `after_commit` |
|--|----------------|----------------|
| 実行タイミング | INSERT 直後（トランザクション内） | COMMIT 後 |
| ロールバック時 | 実行される | 実行されない |
| 監査ログに適切 | × (ロールバック後に不整合が残る) | ○ |

---

## `saved_change_to_id?` の活用

`after_commit` は create・update 両方で呼ばれるため、どちらかを区別します:

```ruby
event: "weekly_report_#{saved_change_to_id? ? 'created' : 'updated'}"
# saved_change_to_id? は ID が変わった（= 新規作成）場合に true
```

---

## Trackable Concern との連携

`include Trackable` で追加されるコールバック:

```ruby
# app/models/concerns/trackable.rb
included do
  after_create  { Rails.logger.info "[Trackable] #{self.class.name} created: #{id}" }
  after_update  { Rails.logger.info "[Trackable] #{self.class.name} updated: #{id}" }
end
```

詳細: [03_concern.md](03_concern.md)

---

## コンソールで確認

```ruby
# レポート作成
report = WeeklyReport.create!(
  user: User.first,
  period_start: Date.today - 14,
  period_end: Date.today - 8,
  avg_weight_g: 70_000
)

# 監査ログが自動作成されていることを確認
AuditLog.last
# => #<AuditLog
#      auditable_type: "WeeklyReport",
#      auditable_id: 1,
#      event: "weekly_report_created",
#      user_id: 1,
#      payload: {"period_start"=>"2024-01-01", "period_end"=>"2024-01-07", "notified_at"=>nil}>

# レポート更新
report.touch  # updated_at を更新

# 更新の監査ログも記録される
report.audit_logs.order(:created_at).pluck(:event)
# => ["weekly_report_created", "weekly_report_updated"]
```

---

## Callback のメリット

| 問題（手動での監査ログ作成） | 解決（Callback） |
|-----------------------------|----------------|
| 各保存箇所で `AuditLog.create!` を呼び忘れる | `after_commit` で自動化 |
| ロールバック後に監査ログが残る | `after_commit` はコミット後のみ実行 |
| 監査ロジックがビジネスロジックに混入 | Callback に分離 |

---

## 設計のポイント

- **`after_commit` を使う**: `after_save` は트랜잭션内で実行されるため、ロールバック時に監査ログだけ残る不整合が起きる
- **ポリモーフィック関連**: `AuditLog` は `WeeklyReport` だけでなく他のモデルにも適用可能
- **JSONB payload**: 構造化されたデータを柔軟に保存できる（スキーマ変更不要）
- **Callback は副作用に限定**: Callback 内でビジネスロジックを書かない
