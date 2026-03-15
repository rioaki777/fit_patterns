# 05. Policy Object（ポリシーオブジェクト）

## 概要

**認可（誰が何をできるか）のロジックをクラスに分離したもの**。
コントローラーに `if current_user.admin?` のような条件が散らばるのを防ぎます。

---

## 実装ファイル

`app/policies/weekly_report_policy.rb`

```ruby
class WeeklyReportPolicy
  def initialize(user, report)
    @user = user
    @report = report
  end

  def create?
    @user.present?
  end

  def show?
    @report.user_id == @user&.id
  end

  def destroy?
    @user&.admin?
  end
end
```

---

## どこで使われるか

`app/controllers/weekly_reports_controller.rb`:

```ruby
class WeeklyReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_report, only: [:show, :destroy]
  before_action :authorize!, only: [:show, :destroy]

  def create
    @form = WeeklyReportForm.new(weekly_report_params)
    policy = WeeklyReportPolicy.new(current_user, nil)

    # create? の確認（nil レポートに対してチェック）
    return redirect_to root_path, alert: "権限がありません" unless policy.create?

    # ...
  end

  private

  def authorize!
    policy = WeeklyReportPolicy.new(current_user, @report)

    # show? の確認（自分のレポートかどうか）
    redirect_to root_path, alert: "権限がありません" unless policy.show?
  end
end
```

---

## ポリシーメソッド一覧

| メソッド | 条件 | 用途 |
|----------|------|------|
| `create?` | ログイン済みユーザーなら true | レポート生成の認可 |
| `show?` | レポートの `user_id` が自分と一致 | 他ユーザーのレポートアクセス禁止 |
| `destroy?` | `admin?` が true のユーザーのみ | 管理者のみ削除可能 |

---

## コンソールで確認

```ruby
user = User.first
report = WeeklyReport.first

# 自分のレポートは見られる
policy = WeeklyReportPolicy.new(user, report)
policy.create?   # => true
policy.show?     # => report.user_id == user.id の場合 true

# 別ユーザーのレポートは見られない
other_user = User.second
policy2 = WeeklyReportPolicy.new(other_user, report)
policy2.show?    # => false (user_id が一致しない)

# admin? は User モデルに定義されていないので false
policy.destroy?  # => false
```

---

## Policy Object のメリット

| 問題（コントローラー内の認可） | 解決（Policy Object） |
|-------------------------------|----------------------|
| 認可ロジックがコントローラーに散在 | Policy クラスに集約 |
| テストが書きにくい | Policy を単体テストできる |
| 複数アクションで同じチェックが重複 | Policy のメソッドを再利用 |

---

## テスト例

```ruby
RSpec.describe WeeklyReportPolicy do
  let(:user)   { build(:user) }
  let(:report) { build(:weekly_report, user: user) }
  let(:policy) { described_class.new(user, report) }

  describe "#create?" do
    it "ログイン済みユーザーは作成可能" do
      expect(policy.create?).to be true
    end

    it "未ログインユーザーは作成不可" do
      policy = described_class.new(nil, nil)
      expect(policy.create?).to be false
    end
  end

  describe "#show?" do
    it "自分のレポートは閲覧可能" do
      expect(policy.show?).to be true
    end

    it "他人のレポートは閲覧不可" do
      other_user = build(:user)
      policy = described_class.new(other_user, report)
      expect(policy.show?).to be false
    end
  end
end
```

---

## 設計のポイント

- `initialize(user, report)` — user（誰が）と resource（何に対して）を受け取る
- メソッド名は `動詞?` で統一（`create?`, `show?`, `destroy?`）
- Policy Object は純粋な Ruby クラス — ActiveRecord に依存しない
- Pundit gem を使えばこのパターンがフレームワーク化される
