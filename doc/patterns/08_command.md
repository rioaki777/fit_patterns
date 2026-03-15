# 08. Command（コマンド）

## 概要

**1つの操作をカプセル化し、成功/失敗を Result オブジェクトで返すクラス**。
コントローラーから呼ばれ、バリデーション・例外を吸収して統一インターフェースを提供します。

---

## 実装ファイル

`app/commands/generate_weekly_report_command.rb`

```ruby
class GenerateWeeklyReportCommand
  Result = Struct.new(:success?, :report, :errors, keyword_init: true)
  # ↑ 戻り値の型を Struct で定義（success?, report, errors の3つ）

  def self.call(user:, form:)
    new(user:, form:).call
  end

  def initialize(user:, form:)
    @user = user
    @form = form
  end

  def call
    unless @form.valid?
      return Result.new(success?: false, report: nil, errors: @form.errors)
    end

    report = GenerateWeeklyReportWorkflow.call(user: @user, form: @form)
    Result.new(success?: true, report:, errors: nil)
  rescue => e
    Result.new(success?: false, report: nil, errors: [e.message])
  end
end
```

---

## Result Struct の構造

```ruby
Result = Struct.new(:success?, :report, :errors, keyword_init: true)
```

| フィールド | 型 | 意味 |
|-----------|-----|------|
| `success?` | Boolean | 処理が成功したか |
| `report` | WeeklyReport または nil | 生成されたレポート |
| `errors` | ActiveModel::Errors または Array または nil | エラー情報 |

---

## どこで使われるか

`app/controllers/weekly_reports_controller.rb`:

```ruby
def create
  @form = WeeklyReportForm.new(weekly_report_params)
  policy = WeeklyReportPolicy.new(current_user, nil)
  return redirect_to root_path, alert: "権限がありません" unless policy.create?

  result = GenerateWeeklyReportCommand.call(user: current_user, form: @form)
  # ↑ Result を受け取る

  if result.success?
    redirect_to weekly_report_path(result.report), notice: "レポートを生成しました"
  else
    render :new, status: :unprocessable_entity
    # @form.errors は Command の中でセットされている
  end
end
```

---

## Command の実行フロー

```
GenerateWeeklyReportCommand.call(user:, form:)
    │
    ├─[バリデーション失敗]
    │   form.valid? → false
    │   └── Result.new(success?: false, errors: form.errors)
    │
    ├─[正常系]
    │   GenerateWeeklyReportWorkflow.call(user:, form:)
    │   └── Result.new(success?: true, report: <WeeklyReport>)
    │
    └─[例外発生]
        rescue => e
        └── Result.new(success?: false, errors: [e.message])
```

---

## コンソールで確認

```ruby
user = User.first

# 正常ケース
form = WeeklyReportForm.new(
  period_start: Date.today - 7,
  period_end: Date.today,
  notification_channel: "email"
)
result = GenerateWeeklyReportCommand.call(user: user, form: form)
result.success?  # => true
result.report    # => #<WeeklyReport id: 1, ...>
result.errors    # => nil

# バリデーションエラー
form = WeeklyReportForm.new(
  period_start: Date.today,
  period_end: Date.today - 1,   # 開始 > 終了
  notification_channel: "email"
)
result = GenerateWeeklyReportCommand.call(user: user, form: form)
result.success?              # => false
result.report                # => nil
result.errors.full_messages  # => ["Period start は終了日より前..."]
```

---

## Command のメリット

| 問題（コントローラー内ロジック） | 解決（Command） |
|---------------------------------|----------------|
| コントローラーにバリデーション・例外処理が混在 | Command に集約 |
| 成功/失敗の判定ロジックが散在 | Result Struct で統一 |
| コントローラーのテストが複雑 | Command を単体テストできる |
| 戻り値の形式がバラバラ | `result.success?` / `result.report` で統一 |

---

## 設計のポイント

- `Result = Struct.new(...)` をコマンドクラスの内側に定義することで名前空間を明確化
- `user:` はコントローラーから渡す（Form Object に持たせない）
- `rescue => e` で広く拾い、Result に包む — コントローラーは例外を意識しない
- Command は1つの操作に対して1つ（GenerateWeeklyReport、CancelReport など）
