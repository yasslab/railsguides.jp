サインアップ機能と設定機能の構築ガイド
====================

本ガイドでは、[Railsをはじめよう](getting_started.html)ガイドの`store`というeコマースアプリケーションにサインアップ機能と設定機能を追加する方法について解説します。本ガイドでは、『Railsをはじめよう』ガイドの最終コードを出発点とします。

このガイドの内容:

* ユーザーのサインアップ機能を追加
* コントローラーアクションのレート制限
* ネステッドレイアウトの作成
* ロール（ユーザーと管理者）ごとにコントローラを分ける
* ロールの異なるユーザーに対するテストの作成

--------------------------------------------------------------------------------

はじめに
------------

サインアップ（sign up）機能は、新しいユーザーを登録する処理であり、アプリケーションに追加する最も一般的な機能の1つです。[Railsをはじめよう](getting_started.html)ガイドで構築したeコマースアプリケーションには認証機能しかなく、ユーザーを登録するにはRailsコンソールやスクリプトで作成しなければなりません。

このサインアップ機能は、他の機能を追加する前に実装しておく必要があります。たとえば、ユーザーがウィッシュリストを作成可能にするには、まずユーザーがサインアップできる必要があります。その後、アカウントに関連付けられたウィッシュリストを作成できます。

それでは始めましょう。

サインアップ機能を追加する
--------------

認証機能ジェネレータでユーザーを自分のアカウントにログインさせる機能は、既にに[Railsをはじめよう](getting_started.html#認証機能を追加する)ガイドで使いました。認証機能ジェネレータを用いて、`User`モデルを作成し、データベースに`email_address:string`と`password_digest:string`のカラムを追加しました。また、`User`モデルに`has_secure_password`メソッドを追加し、パスワードと確認を処理します。これにより、サインアップ機能をアプリケーションに追加するために必要な処理はほぼ完了します。

### ユーザーに名前を追加する

サインアップのときに、ユーザーの名前も保存しておくとよいでしょう。これにより、アプリケーション内でユーザー体験をパーソナライズし、ユーザーを「XX様」のように直接名前で呼びかけることが可能になります。

それでは、データベースに`first_name`と`last_name`のカラムを追加しましょう。

ターミナルで以下のコマンドを実行して、これらのカラムを持つマイグレーションを作成します。

```bash
$ bin/rails g migration AddNamesToUsers first_name:string last_name:string
```

Then migrate the database:

```bash
$ bin/rails db:migrate
```

`first_name`と`last_name`をつなげるメソッドも追加して、ユーザーのフルネームを表示できるようにしておきましょう。

`app/models/user.rb`ファイルを開いて、以下を追加します。

<!-- コードブロックのハイライトが日本語版にないため、削除しています -->

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :first_name, :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
```

TIP: `has_secure_password`メソッドは、パスワードがパスワードが存在することだけをバリデーションします。セキュリティを強化するため、パスワードの最小文字数のチェックやパスワードが十分複雑かどうかのバリデーションも追加することを検討しましょう。

次に、サインアップ機能を追加して新しいユーザーを登録できるようにしましょう。

### サインアップ用のルーティングとコントローラ

新しいユーザーを登録するのに必要なカラムがすべて揃ったので、次のステップではサインアップ用のルーティングとそれに対応するコントローラを作成します。

`config/routes.rb`にサインアップ用のリソースを追加します。

```ruby
resource :session
resources :passwords, param: :token
resource :sign_up
```

ここでは、`/sign_up`に対する単一のルーティングを作成するために、単数形の`resource`を使っています。

このルーティングは、リクエストを`app/controllers/sign_ups_controller.rb`に送信します。次は、そのルーティングに対応するコントローラファイルを作成しましょう。

```ruby
class SignUpsController < ApplicationController
  def show
    @user = User.new
  end
end
```

`User`の新しいインスタンスを作成するために、`show`アクションを使っています。これはサインアップフォームを表示するアクションです。

次に、フォームを作成しましょう。`app/views/sign_ups/show.html.erb`を作成し、以下のコードを追加します。

```erb
<h1>Sign Up</h1>

<%= form_with model: @user, url: sign_up_path do |form| %>
  <% if form.object.errors.any? %>
    <div>Error: <%= form.object.errors.full_messages.first %></div>
  <% end %>

  <div>
    <%= form.label :first_name %>
    <%= form.text_field :first_name, required: true, autofocus: true, autocomplete: "given-name" %>
  </div>

  <div>
    <%= form.label :last_name %>
    <%= form.text_field :last_name, required: true, autocomplete: "family-name" %>
  </div>

  <div>
    <%= form.label :email_address %>
    <%= form.email_field :email_address, required: true, autocomplete: "email" %>
  </div>

  <div>
    <%= form.label :password %>
    <%= form.password_field :password, required: true, autocomplete: "new-password" %>
  </div>

  <div>
    <%= form.label :password_confirmation %>
    <%= form.password_field :password_confirmation, required: true, autocomplete: "new-password" %>
  </div>

  <div>
    <%= form.submit "Sign up" %>
  </div>
<% end %>
```

このフォームは、ユーザーの名前、メールアドレス、パスワードを収集します。`autocomplete`属性を用いて、ブラウザに保存されたユーザー情報に基づいて、これらのフィールドの値を自動的に補完します。

このフォームでは、`model: @user`と一緒に`url: sign_up_path`も指定していることにご注意ください。`form_with`メソッドに`url:`引数を指定しない場合は、`User`モデルが存在すると見なして、フォームをデフォルトで`/users`に送信します。ここではフォームを`/users`ではなく`/sign_up`に送信したいので、`url:`を設定してデフォルトのルーティングをオーバーライドしています。

再び`app/controllers/sign_ups_controller.rb`をエディタで開いて、フォームの送信を処理する`create`アクションを追加します。

```ruby
class SignUpsController < ApplicationController
  def show
    @user = User.new
  end

  def create
    @user = User.new(sign_up_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to root_path
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def sign_up_params
      params.expect(user: [ :first_name, :last_name, :email_address, :password, :password_confirmation ])
    end
end
```

`create`アクションはパラメータを割り当てて、データベースにユーザーを保存することを試みます。保存に成功した場合はユーザーをログインさせて`root_path`にリダイレクトし、失敗した場合はエラー付きのフォームを再表示します。

ブラウザで`https://localhost:3000/sign_up`を開いて、フォームが正しく動作することを確認してみましょう。

### アカウント作成時にログインなしのアクセスを必須にする

認証されたユーザーは、ログインした状態のまま`SignUpsController`にアクセスして別のアカウントを作成できてしまうため、このままでは混乱を招く可能性があります。

これを修正するために、`app/controllers/concerns/authentication.rb`ファイルの`Authentication`モジュールにヘルパーを追加しましょう。

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def unauthenticated_access_only(**options)
      allow_unauthenticated_access **options
      before_action -> { redirect_to root_path if authenticated? }, **options
    end

    # ...
```

`unauthenticated_access_only`クラスメソッドは、アクションの利用を認証されていないユーザーのみに限定したいコントローラで利用できます。

このメソッドを`SignUpsController`の冒頭で以下のように追加できます。

```ruby
class SignUpsController < ApplicationController
  unauthenticated_access_only

  # ...
end
```

### サインアップにレート制限を追加する

このアプリケーションはインターネット上でアクセス可能になるため、悪意のあるボットやユーザーがアプリケーションにスパムの送信を試みる可能性があります。サインアップにレート制限を追加して、大量のリクエストを送信するユーザーのアクセス速度を下げることが可能です。

Railsでは、コントローラ内で[`rate_limit`](https://api.rubyonrails.org/classes/ActionController/RateLimiting/ClassMethods.html)メソッドを使ってレート制限を簡単に実現できます。

```ruby
class SignUpsController < ApplicationController
  unauthenticated_access_only
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to sign_up_path, alert: "Try again later." }

  # ...
end
```

これで、サインアップフォームの送信頻度が3分間あたり10回を超えると、リクエストがブロックされるようになります。

パスワードの編集機能
-----------------

ユーザーがログインできるようになったので、ユーザーが期待する「プロフィール」「パスワード」「メールアドレス」などの設定を更新するための場所をすべて作成しましょう。

### 名前空間を使ったパスワードルーティング

パスワードリセット用の`app/controllers/passwords_controller.rb`コントローラは、Railsの認証ジェネレータによって既に作成されています。つまり、認証済みユーザーのパスワードを編集するには、別のコントローラを使う必要があります。

この競合を防ぐために、**名前空間**と呼ばれる機能を利用できます。名前空間は、ルーティング、コントローラ、ビューをフォルダに整理し、2つのパスワードコントローラのような競合を防ぐのに役立ちます。

ここでは"Settings"という名前空間を作成して、ユーザーとストアの設定をアプリケーションの他の部分から分離することにします。

`config/routes.rb`ファイルにSettings名前空間を追加し、その内側にパスワード編集用のリソースを追加します。

```ruby
namespace :settings do
  resource :password, only: [ :show, :update ]
end
```

これにより、現在のユーザーのパスワードを編集するための`/settings/password`ルーティングが別途生成されます。これは、`/password`にあるパスワードリセット用のルーティングとは別物です。

### 名前空間化されたパスワードコントローラとビューを追加する

名前空間は、コントローラをRubyの対応するモジュールに移動します。このコントローラは、名前空間に合わせて`settings/`フォルダに配置されます。

`app/controllers/settings/`フォルダと`app/controllers/settings/passwords_controller.rb`コントローラを作成します。最初は`show`アクションを作成しましょう。

```ruby
class Settings::PasswordsController < ApplicationController
  def show
  end
end
```

対応するビューも`settings/`フォルダに移動するので、この`show`アクションに対応するフォルダとビューを`app/views/settings/passwords/show.html.erb`に作成しましょう。

```erb
<h1>Password</h1>

<%= form_with model: Current.user, url: settings_password_path do |form| %>
  <% if form.object.errors.any? %>
    <div><%= form.object.errors.full_messages.first %></div>
  <% end %>

  <div>
    <%= form.label :password_challenge %>
    <%= form.password_field :password_challenge, required: true, autocomplete: "current-password" %>
  </div>

  <div>
    <%= form.label :password %>
    <%= form.password_field :password, required: true, autocomplete: "new-password" %>
  </div>

  <div>
    <%= form.label :password_confirmation %>
    <%= form.password_field :password_confirmation, required: true, autocomplete: "new-password" %>
  </div>

  <div>
    <%= form.submit "Update password" %>
  </div>
<% end %>
```

名前空間化されたルーティングにフォームが送信されるよう、フォームで`url:`引数を設定してあるので、リクエストは`Settings::PasswordsController`で処理されます。

`form_with`に`model: Current.user`引数を渡してあるので、フォームを`update`アクションで処理するときは`PATCH`リクエストを送信します。

TIP: `Current.user`は、Active Supportの[`CurrentAttributes`](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html)から来ています。これはリクエストごとの属性であり、各リクエストの前後で自動的にリセットされます。Railsの認証ジェネレータはこれを利用して、ログインしているユーザーをトラッキングしています。

### パスワードを安全に更新する

コントローラに`update`アクションを追加しましょう。

```ruby
class Settings::PasswordsController < ApplicationController
  def show
  end

  def update
    if Current.user.update(password_params)
      redirect_to settings_profile_path, status: :see_other, notice: "Your password has been updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def password_params
      params.expect(user: [ :password, :password_confirmation, :password_challenge ]).with_defaults(password_challenge: "")
    end
end
```

セキュリティを維持するために、ユーザー本人だけがパスワードを更新できるようにする必要があります。`User`モデルの`has_secure_password`メソッドはこの属性を提供します。`password_challenge`フィールドが存在する場合、データベース内のユーザーの現在のパスワードと照合して一致することを確認します。

悪意のあるユーザーがブラウザで`password_challenge`フィールドそのものを削除してこのバリデーションを回避しようとする可能性があります。これを防いでバリデーションが常に実行されるようにするために、`password_challenge`パラメータが存在しない場合でもデフォルト値を設定するために`.with_defaults(password_challenge: "")`を呼び出しています。

これで、ユーザーはブラウザで`http://localhost:3000/settings/password`にアクセスしてパスワードを更新できるようになりました。

### `password_challenge`属性をリネームする

`password_challenge`という名前はコード上では適切ですが、ユーザーにとってはこのフォームフィールドが「Current password（現在のパスワード）」と表示される方が自然です。Railsのロケールを使って、フロントエンドでのこの属性表示をリネームできます。

`config/locales/en.yml`ロケールファイルに以下を追加します。

```yaml
en:
  hello: "Hello world"
  products:
    index:
      title: "Products"

  activerecord:
    attributes:
      user:
        password_challenge: "Current password"
```

詳しくは、[国際化（I18n）ガイド](i18n.html#active-recordモデルで翻訳を行なう)を参照してください。

ユーザープロファイルを編集する
---------------------

次は、ユーザーがプロフィールを編集できるページを追加しましょう（名前の変更など）。

### プロファイル用のルーティングとコントローラ

`config/routes.rb`ファイルを開いて、Settings名前空間の下にプロファイルリソースを追加します。名前空間に`root`を追加することで、`/settings`へのアクセスを処理してプロフィール設定にリダイレクトすることも可能です。

```ruby
namespace :settings do
  resource :password, only: [ :show, :update ]
  resource :profile, only: [ :show, :update ]

  root to: redirect("/settings/profile")
end
```

プロファイル編集用のコントローラを`app/controllers/settings/profiles_controller.rb`に作成しましょう。

```ruby
class Settings::ProfilesController < ApplicationController
  def show
  end

  def update
    if Current.user.update(profile_params)
      redirect_to settings_profile_path, status: :see_other, notice: "Your profile was updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def profile_params
      params.expect(user: [ :first_name, :last_name ])
    end
end
```

このコントローラは、パスワードココントローラと非常に似ていますが、ユーザーのプロフィールの詳細（名前など）を更新することしかできない点が異なります。

続いて、プロファイル編集フォームを表示する`app/views/settings/profiles/show.html.erb`を作成しましょう。

```erb
<h1>Profile</h1>

<%= form_with model: Current.user, url: settings_profile_path do |form| %>
  <% if form.object.errors.any? %>
    <div>Error: <%= form.object.errors.full_messages.first %></div>
  <% end %>

  <div>
    <%= form.label :first_name %>
    <%= form.text_field :first_name, required: true, autocomplete: "given-name" %>
  </div>

  <div>
    <%= form.label :last_name %>
    <%= form.text_field :last_name, required: true, autocomplete: "family-name" %>
  </div>

  <div>
    <%= form.submit "Update profile" %>
  </div>
<% end %>
```

これで、ブラウザで`http://localhost:3000/settings/profile`にアクセスして、プロフィールを更新できるようになりました。

### 更新用のリンクを更新する

更新用のリンクを更新してログアウトボタンの横に配置し、「Settings」にリンクしましょう。

`app/views/layouts/application.html.erb`レイアウトを開いて、ナビゲーションバーを更新します。ここで、コントローラからのアラートメッセージを表示するための`<div>`も追加します。

```erb
<!DOCTYPE html>
<html>
  <head>
    <%# ... %>
  </head>

  <body>
    <div class="notice"><%= notice %></div>
    <div class="alert"><%= alert %></div>

    <nav class="navbar">
      <%= link_to "Home", root_path %>
      <% if authenticated? %>
        <%= link_to "Settings", settings_root_path %>
        <%= button_to "Log out", session_path, method: :delete %>
      <% else %>
        <%= link_to "Sign Up", sign_up_path %>
        <%= link_to "Login", new_session_path %>
      <% end %>
    </nav>
```

これで、ユーザーが認証されると、ナビゲーションバーに「Settings」リンクが表示されるようになります。

### 「Settings」にレイアウトを追加する

ついでに、「Settings」用の新しいレイアウトを追加して、設定をサイドバーで整理できるようにしましょう。これは[ネステッドレイアウト](layouts_and_rendering.html#ネステッドレイアウトを使う)（nested layout）で実現します。

ネステッドレイアウトを使うことで、アプリケーションレイアウトをレンダリングしつつ、HTML（サイドバーなど）を追加できます。これにより、「Settings」のレイアウトでヘッドタグやナビゲーションを重複させる必要がなくなります。

`app/views/layouts/settings.html.erb`レイアウトファイルを作成して、以下を追加します。

```erb
<%= content_for :content do %>
  <section class="settings">
    <nav>
      <h4>Account Settings</h4>
      <%= link_to "Profile", settings_profile_path %>
      <%= link_to "Password", settings_password_path %>
    </nav>

    <div>
      <%= yield %>
    </div>
  </section>
<% end %>

<%= render template: "layouts/application" %>
```

「Settings」のレイアウトではサイドバー用のHTMLを提供し、アプリケーションレイアウトを親としてレンダリングするようRailsに指示しています。

そのためには、`yield(:content)`を使って、ネステッドレイアウトからのコンテンツをレンダリングするようにアプリケーションレイアウト（`app/views/layouts/application.html.erb`）を修正する必要があります。

```erb
<!DOCTYPE html>
<html>
  <head>
    <%# ... %>
  </head>

  <body>
    <div class="notice"><%= notice %></div>
    <div class="alert"><%= alert %></div>

    <nav class="navbar">
      <%= link_to "Home", root_path %>
      <% if authenticated? %>
        <%= link_to "Settings", settings_root_path %>
        <%= button_to "Log out", session_path, method: :delete %>
      <% else %>
        <%= link_to "Sign Up", sign_up_path %>
        <%= link_to "Login", new_session_path %>
      <% end %>
    </nav>

    <main>
      <%= content_for?(:content) ? yield(:content) : yield %>
    </main>
  </body>
</html
```

これにより、アプリケーションコントローラを`yield`で通常通りに利用できるようになります。ネステッドレイアウト内で`content_for(:content)`が使われている場合は、親レイアウトとしても利用できます。

2つのレイアウトの両方に`<nav>`タグがあるため、CSSセレクタを更新して競合を避ける必要があります。

これを行うには、`app/assets/stylesheets/application.css`ファイル内にあるこれらのセレクタに`.navbar`クラスを追加します。

```css
nav.navbar {
  justify-content: flex-end;
  display: flex;
  font-size: 0.875em;
  gap: 0.5rem;
  max-width: 1024px;
  margin: 0 auto;
  padding: 1rem;
}

nav.navbar a {
  display: inline-block;
}
```

次に、「Settings」レイアウトにサイドバー用のスタイルを設定します。

```css
section.settings {
  display: flex;
  gap: 1rem;
}

section.settings nav {
  width: 200px;
}

section.settings nav a {
  display: block;
}
```

コントローラで特定のレイアウトを指定することで、この新しいレイアウトを利用できます。`layout "settings"`を任意のコントローラに追加することで、レンダリングされるレイアウトを変更できます。

このレイアウトは多くのコントローラで利用されるため、設定を共有するためのベースクラスを作成して共有設定を定義し、継承を使ってそれらを利用できます。

`app/controllers/settings/base_controller.rb`ファイルを作成し、以下を追加します。

```ruby
class Settings::BaseController < ApplicationController
  layout "settings"
end
```

次に、`app/controllers/settings/passwords_controller.rb`を更新して、このコントローラがベースコントローラを継承するようにします。

```ruby
class Settings::PasswordsController < Settings::BaseController
```

`app/controllers/settings/profiles_controller.rb`も同様に更新して、ベースコントローラを継承するようにします。

```ruby
class Settings::ProfilesController < Settings::BaseController
```

アカウントを削除する
-----------------

次に、アカウントを削除する機能を追加しましょう。
まず、`config/routes.rb`ファイルにアカウント用の別の名前空間化ルーティングを追加します。

```ruby
namespace :settings do
  resource :password, only: [ :show, :update ]
  resource :profile, only: [ :show, :update ]
  resource :user, only: [ :show, :destroy ]

  root to: redirect("/settings/profile")
end
```

これらの新しいルーティングを処理するために、`app/controllers/settings/users_controller.rb`ファイルを作成し、以下を追加します。

```ruby
class Settings::UsersController < Settings::BaseController
  def show
  end

  def destroy
    terminate_session
    Current.user.destroy
    redirect_to root_path, notice: "Your account has been deleted."
  end
end
```

アカウント削除用のコントローラは非常にシンプルです。`show`アクションでページを表示し、`destroy`アクションでログアウトしてユーザーを削除します。また、他のコントローラと同様に`Settings::BaseController`を継承しているため、「Settings」レイアウトが使われます。

次に、`app/views/settings/users/show.html.erb`ファイルに以下のビューを追加します。

```erb
<h1>Account</h1>

<%= button_to "Delete my account", settings_user_path, method: :delete, data: { turbo_confirm: "Are you sure? This cannot be undone." } %>
```

最後に、「Settings」レイアウトのサイドバーにアカウントへのリンクを追加します。

```erb
<%= content_for :content do %>
  <section class="settings">
    <nav>
      <h4>Account Settings</h4>
      <%= link_to "Profile", settings_profile_path %>
      <%= link_to "Password", settings_password_path %>
      <%= link_to "Account", settings_user_path %>
    </nav>

    <div>
      <%= yield %>
    </div>
  </section>
<% end %>

<%= render template: "layouts/application" %>
```

できました！これでアカウントを削除できるようになりました。

メールアドレスの更新機能を追加する
------------------------

ユーザーがメールアドレスを変更する必要が生じることがあります。安全に変更を行うために、新しいメールアドレスを保存し、変更を確認するためのメールを送信する必要があります。

### ユーザーによる確認が完了していないメールをusersテーブルに追加する

まず、データベースのusersテーブルに新しいフィールドを追加します。これは、確認を待っている間に新しいメールアドレスを保存するためのものです。

```bash
$ bin/rails g migration AddUnconfirmedEmailToUsers unconfirmed_email:string
```

続いて、データベースのマイグレーションを実行します。

```bash
$ bin/rails db:migrate
```

### メール用のルーティングとコントローラを追加する

次に、`config/routes.rb`ファイル内の`settings`名前空間にメール用のルーティングを追加します。

```ruby
namespace :settings do
  resource :email, only: [ :show, :update ]
  resource :password, only: [ :show, :update ]
  resource :profile, only: [ :show, :update ]
  resource :user, only: [ :show, :destroy ]

  root to: redirect("/settings/profile")
end
```

次に、これを表示するための`app/controllers/settings/emails_controller.rb`ファイルを作成します。

```ruby
class Settings::EmailsController < Settings::BaseController
  def show
  end
end
```

最後に、`app/views/settings/emails/show.html.erb`ファイルに以下の内容でビューを作成します。

```erb
<h1>Change Email</h1>

<%= form_with model: Current.user, url: settings_email_path do |form| %>
  <% if form.object.errors.any? %>
    <div>Error: <%= form.object.errors.full_messages.first %></div>
  <% end %>

  <div>
    <%= form.label :unconfirmed_email, "New email address" %>
    <%= form.email_field :unconfirmed_email, required: true %>
  </div>

  <div>
    <%= form.label :password_challenge %>
    <%= form.password_field :password_challenge, required: true, autocomplete: "current-password" %>
  </div>

  <div>
    <%= form.submit "Update email address" %>
  </div>
<% end %>
```

処理をセキュアにするため、新しいメールアドレスをユーザーが入力したら、ユーザーの現在のパスワードをバリデーションして、アカウントの所有者だけがメールを変更できるようにする必要があります。

コントローラの`update`アクションでは、現在のパスワードをバリデーションし、新しいメールアドレスをテーブルに保存してから、新しいメールアドレスを確認するためのメールを送信します。

```ruby
class Settings::EmailsController < Settings::BaseController
  def show
  end

  def update
    if Current.user.update(email_params)
      UserMailer.with(user: Current.user).email_confirmation.deliver_later
      redirect_to settings_email_path, status: :see_other, notice: "We've sent a verification email to #{Current.user.unconfirmed_email}."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def email_params
      params.expect(user: [ :password_challenge, :unconfirmed_email ]).with_defaults(password_challenge: "")
    end
end
```

ここでは、`Settings::PasswordsController`の場合と同じ`with_defaults(password_challenge: "")`を使って、パスワードチャレンジのバリデーションをトリガーしています。

次に、まだ作成していなかった`UserMailer`メーラーを作成する必要があります。

### 新しいメールの確認

Railsのメーラージェネレータを使って、`Settings::EmailsController`で参照されている`UserMailer`を作成しましょう。

```bash
$ bin/rails generate mailer User email_confirmation
      create  app/mailers/user_mailer.rb
      invoke  erb
      create    app/views/user_mailer
      create    app/views/user_mailer/email_confirmation.text.erb
      create    app/views/user_mailer/email_confirmation.html.erb
      invoke  test_unit
      create    test/mailers/user_mailer_test.rb
      create    test/mailers/previews/user_mailer_preview.rb
```

メール本文に含めるためのトークンを生成する必要があります。`app/models/user.rb`ファイルを開いて、以下を追加します。

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :first_name, :last_name, presence: true

  generates_token_for :email_confirmation, expires_in: 7.days do
    unconfirmed_email
  end

  def confirm_email
    update(email_address: unconfirmed_email, unconfirmed_email: nil)
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
```

これで、メール確認用のトークンを生成する`generates_token_for`メソッドが追加されました。このトークンには確認完了前のメールアドレスがエンコードされるため、メールアドレスが異なっていたりトークンが期限切れになった場合は無効になります。

次に、`app/mailers/user_mailer.rb`ファイルを更新して、メール用の新しいトークンを生成しましょう。

```ruby
class UserMailer < ApplicationMailer
  # メールの件名は、I18n用のconfig/locales/en.ymlファイルで以下のように設定可能
  #
  #   en.user_mailer.email_confirmation.subject
  def email_confirmation
    @token = params[:user].generate_token_for(:email_confirmation)
    mail to: params[:user].unconfirmed_email
  end
end
```

このトークン（`@token`）を、`app/views/user_mailer/email_confirmation.html.erb`ファイルのHTMLビューに含めます。

```erb
<h1>Verify your email address</h1>

<p><%= link_to "Confirm your email", email_confirmation_url(token: @token) %></p>
```

`app/views/user_mailer/email_confirmation.text.erb`ファイルにも同様にトークンを含めます。

```erb
Confirm your email: <%= email_confirmation_url(token: @token) %>
```

### メール確認

確認メールには、Railsアプリへのリンクが含まれています。このリンクをクリックすると、メールアドレスの変更が確認されます。

`config/routes.rb`ファイルで以下のようにルーティングを追加しましょう。

```ruby
namespace :email do
  resources :confirmations, param: :token, only: [ :show ]
end
```

ユーザーが確認メールのリンクをクリックすると、アプリがGETリクエストを受け取ります。このため、このコントローラで必要なのは`show`アクションだけです。

次に、`app/controllers/email/confirmations_controller.rb`ファイルに以下を追加します。

```ruby
class Email::ConfirmationsController < ApplicationController
  allow_unauthenticated_access

  def show
    user = User.find_by_token_for(:email_confirmation, params[:token])
    if user&.confirm_email
      flash[:notice] = "Your email has been confirmed."
    else
      flash[:alert] = "Invalid token."
    end
    redirect_to root_path
  end
end
```

メールアドレスの確認は、ユーザーが認証済みであってもなくても行えるようにしたいので、このコントローラでは認証されていないアクセスを許可しています。トークンを`find_by_token_for`メソッドで検証し、`User`モデル内の一致するレコードを検索します。成功した場合は、`confirm_email`メソッドを呼び出してユーザーのメールアドレスを更新し、`unconfirmed_email`を`nil`にリセットします。トークンが有効でない場合、`user`変数は`nil`になり、アラートメッセージを表示します。

最後に、「Settings」レイアウトのサイドバーにメール送信用のリンクを追加しましょう（`settings_email_path`）。

```erb
<%= content_for :content do %>
  <section class="settings">
    <nav>
      <h4>Account Settings</h4>
      <%= link_to "Profile", settings_profile_path %>
      <%= link_to "Email", settings_email_path %>
      <%= link_to "Password", settings_password_path %>
      <%= link_to "Account", settings_user_path %>
    </nav>

    <div>
      <%= yield %>
    </div>
  </section>
<% end %>

<%= render template: "layouts/application" %>
```

この機能を試すには、ブラウザで`https://localhost:3000/settings/email`を開いてメールアドレスを更新します。次にメールの内容をRailsサーバーログで確認し、ブラウザで確認リンクを開いてデータベース内のメールアドレスを更新します。

管理者とユーザーを分離する
-------------------------

誰でもstoreアプリでアカウントを作成できるようになったので、通常のユーザーと管理者を区別する必要があります。

### 管理者フラグを追加する

まず、`User`モデルにカラムを追加します。

```bash
$ bin/rails g migration AddAdminToUsers admin:boolean
```

次に、データベースをマイグレーションします。

```bash
$ bin/rails db:migrate
```

`User`モデルで`admin`を`true`に設定すると、そのユーザーはstoreアプリの管理者となり、製品の削除などの管理タスクを実行できるようになります。

### Readonly属性

`admin`属性が悪意のあるユーザーによって編集されることのないように十分注意する必要があります。これは、`:admin`属性を許可されたパラメータリストから外すことで簡単に実現できます。

オプションとして、セキュリティをさらに強化するために`admin`属性を読み取り専用としてマーキングする方法もあります。これにより、`admin`属性が変更されるたびにRailsでエラーが発生するようになります。レコードの作成時には引き続き`admin`属性を設定できますが、不正な変更に対する追加のセキュリティ層が提供されます。ユーザーの`admin`フラグを頻繁に変更する場合はこのオプションを導入しないことも可能ですが、このeコマースストアでは有用な保護手段です。

以下のようにモデルに`attr_readonly`属性を追加することで、属性の更新を防止できます。

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  attr_readonly :admin

  # ...
```

`admin`属性を読み取り専用にすると、`admin`属性をActive Record経由で更新できなくなります。代わりに、データベースに対して直接SQL操作を行って`admin`属性を更新する必要があります。

Railsには、データベースに直接アクセスするための`dbconsole`コマンドがあります。これを用いて、データベースとSQLで直接対話できます。

```bash
$ bin/rails dbconsole
SQLite version 3.43.2 2023-10-10 13:08:14
Enter ".help" for usage hints.
sqlite>
```

表示されたSQLiteプロンプトで、レコードの`admin`カラムを`UPDATE`文で更新し、`WHERE`で特定のユーザーIDに絞り込めます。

```sql
UPDATE users SET admin=true WHERE users.id=1;
```

SQLiteプロンプトを閉じるには、以下のコマンドを入力します。

```
.quit
```

すべてのユーザーを表示する
-----------------

storeアプリの管理者は、顧客サポートやマーケティングなどのユースケースのために、ユーザーの表示や管理機能を必要とします。

まず、`config/routes.rb`ファイルに新しい`store`名前空間でユーザーのルーティングを追加しましょう。

```ruby
# Admins Only
namespace :store do
  resources :users
end
```

### 管理者限定のアクセスを追加する

ユーザーのコントローラへのアクセスは管理者のみに限定する必要があります。コントローラを作成する前に、管理者アクセスのみに制限するクラスメソッドを備えた`Authorization`モジュールを作成しましょう。

`app/controllers/concerns/authorization.rb`ファイルを作成して、以下のコードを追加します。

```ruby
module Authorization
  extend ActiveSupport::Concern

  class_methods do
    def admin_access_only(**options)
      before_action -> { redirect_to root_path, alert: "You aren't allowed to do that." unless authenticated? && Current.user.admin? }, **options
    end
  end
end
```

作成した`Authorization`モジュールをコントローラで利用するには、`app/controllers/application_controller.rb`ファイルで以下のように`include`します。


```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

  # ...
```

この`Authorization`モジュールの機能は、アプリ内の任意のコントローラで利用できます。このモジュールは、将来的に管理者や他のタイプのロールのアクセスを管理するための追加ヘルパーを配置する場所にもなります。

### Usersコントローラとビューを追加する

まず、`app/controllers/store/base_controller.rb`ファイルに`store`名前空間を持つベースクラスを作成します。

```ruby
class Store::BaseController < ApplicationController
  admin_access_only
  layout "settings"
end
```

このコントローラへのアクセスは、先ほど作成した`admin_access_only`メソッドによって管理者のみに制限されます。また、サイドバーを表示するときも同じ「Settings」レイアウトを利用します。

次に、`app/controllers/store/users_controller.rb`ファイルを作成し、以下のコードを追加します。

```ruby
class Store::UsersController < Store::BaseController
  before_action :set_user, only: %i[ show edit update destroy ]

  def index
    @users = User.all
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to store_user_path(@user), status: :see_other, notice: "User has been updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.expect(user: [ :first_name, :last_name, :email_address ])
    end
end
```

これで、管理者はデータベース上のユーザーの一覧表示、編集、更新、削除ができるようになりました。

次に、`app/views/store/users/index.html.erb`ファイルでインデックスビューを作成しましょう。

```erb
<h1><%= pluralize @users.count, "user" %></h1>

<% @users.each do |user| %>
  <div>
    <%= link_to user.full_name, store_user_path(user) %>
  </div>
<% end %>
```

次に、`app/views/store/users/edit.html.erb`ファイルで編集ビューを作成します。

```erb
<h1>Edit User</h1>
<%= render "form", user: @user %>
```

フォームのパーシャルを`app/views/store/users/_form.html.erb`ファイルに作成します。

```erb
<%= form_with model: [ :store, user ] do |form| %>
  <div>
    <%= form.label :first_name %>
    <%= form.text_field :first_name, required: true, autofocus: true, autocomplete: "given-name" %>
  </div>

  <div>
    <%= form.label :last_name %>
    <%= form.text_field :last_name, required: true, autocomplete: "family-name" %>
  </div>

  <div>
    <%= form.label :email_address %>
    <%= form.email_field :email_address, required: true, autocomplete: "email" %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

最後に、ユーザー表示用のビューを`app/views/store/users/show.html.erb`ファイルに作成します。

```erb
<%= link_to "Back to all users", store_users_path %>

<h1><%= @user.full_name %></h1>
<p><%= @user.email_address %></p>

<div>
  <%= link_to "Edit user", edit_store_user_path(@user)  %>
  <%= button_to "Delete user", store_user_path(@user), method: :delete, data: { turbo_confirm: "Are you sure?" } %>
</div>
```

### 「Settings」へのリンクを追加する

次に、この管理画面へのリンクを「Settings」サイドバーのナビゲーションに追加しましょう。これは管理者にのみ表示されるべきなので、現在のユーザーが管理者であることを確認する条件でラップする必要があります。

`app/views/layouts/settings.html.erb`ファイルの「Settings」レイアウトに以下を追加します。

```erb
<%= content_for :content do %>
  <section class="settings">
    <nav>
      <h4>Account Settings</h4>
      <%= link_to "Profile", settings_profile_path %>
      <%= link_to "Email", settings_email_path %>
      <%= link_to "Password", settings_password_path %>
      <%= link_to "Account", settings_user_path %>

      <% if Current.user.admin? %>
        <h4>Store Settings</h4>
        <%= link_to "Users", store_users_path %>
      <% end %>
    </nav>

    <div>
      <%= yield %>
    </div>
  </section>
<% end %>

<%= render template: "layouts/application" %>
```

Productsコントローラを分離する
-------------------------------

一般ユーザーと管理者を分離できたので、これに合わせてProductsコントローラを再編成できるようになりました。従来の単一のProductsコントローラを、公開用と管理用の2つに分割できます。

公開用のProductsコントローラはストアフロントのビューを処理し、管理用のコントローラは製品管理を担当します。

### 公開用のProductsコントローラ

一般向けのストアフロントでは、製品を表示するだけで十分です。つまり、`app/controllers/products_controller.rb`は以下のようにシンプルな形に変更できます。

```ruby
class ProductsController < ApplicationController
  allow_unauthenticated_access

  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
  end
end
```

続いて、Productsコントローラのビューを調整しましょう。

まず、従来のProducts用ビューを`store`名前空間にコピーしましょう。この名前空間でストア用の製品管理を行います。

```bash
$ cp -R app/views/products app/views/store
```

### 公開用のProductsビューをクリーンアップする

それでは、公開用のProductsビューから作成・更新・削除の機能をすべて削除しましょう。

`app/views/products/index.html.erb`ファイルから"New product"へのリンクを削除します。今後は、管理者が「Settings」エリアで新しい製品を作成します。

```diff
-<%= link_to "New product", new_product_path if authenticated? %>
```

`app/views/products/show.html.erb`ファイルから、編集と削除のリンクを削除します。

```diff
-    <% if authenticated? %>
-      <%= link_to "Edit", edit_product_path(@product) %>
-      <%= button_to "Delete", @product, method: :delete, data: { turbo_confirm: "Are you sure?" } %>
-    <% end %>
```

以下はファイルごと削除します。

- `app/views/products/new.html.erb`
- `app/views/products/edit.html.erb`
- `app/views/products/_form.html.erb`

### 管理者用のProducts CRUDを追加する

まず、`config/routes.rb`ファイルにProductsへのルーティングを`store`名前空間付きで追加しましょう。

```ruby
  namespace :store do
    resources :products
    resources :users

    root to: redirect("/store/products")
  end
```

続いて、`app/views/layouts/settings.html.erb`ファイルのサイドバーにProductsの管理画面へのリンクを追加します。

```erb
<%= content_for :content do %>
  <section class="settings">
    <nav>
      <h4>Account Settings</h4>
      <%= link_to "Profile", settings_profile_path %>
      <%= link_to "Email", settings_email_path %>
      <%= link_to "Password", settings_password_path %>
      <%= link_to "Account", settings_user_path %>

      <% if Current.user.admin? %>
        <h4>Store Settings</h4>
        <%= link_to "Products", store_products_path %>
        <%= link_to "Users", store_users_path %>
      <% end %>
    </nav>

    <div>
      <%= yield %>
    </div>
  </section>
<% end %>

<%= render template: "layouts/application" %>
```

次に、`app/controllers/store/products_controller.rb`ファイルを以下の内容で作成します。

```ruby
class Store::ProductsController < Store::BaseController
  before_action :set_product, only: %i[ show edit update destroy ]

  def index
    @products = Product.all
  end

  def show
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to store_product_path(@product)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to store_product_path(@product)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to store_products_path
  end

  private
    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.expect(product: [ :name, :description, :featured_image, :inventory_count ])
    end
end
```

このコントローラは、従来の`ProductsController`とほぼ同じですが、2つの重要な変更点があります。

1. `admin_access_only`を追加して、管理者ユーザーのみにアクセスを制限するようになった。
2. リダイレクトで`store`名前空間を使うことで、管理者ユーザーをストアの「Settings」に留めるようにした。

### 管理者用のProductsビューを更新する

管理者用のビューは、`store`名前空間内で動作するようにいくつかの調整が必要です。

まず、`form_with`メソッドの`model:`引数で`store`名前空間を使うように更新します。また、このビュー内でバリデーションエラーを表示するようにします。

```erb
<%= form_with model: [ :store, product ] do |form| %>
  <% if form.object.errors.any? %>
    <div>Error: <%= form.object.errors.full_messages.first %></div>
  <% end %>

  <div>
    <%= form.label :name %>
    <%= form.text_field :name %>
  </div>

  <%# ... %>
```

`app/views/store/products/index.html.erb`ファイルの`authenticated?`チェックを削除し、リンクも`store`名前空間で更新します。

```erb
<h1><%= t ".title" %></h1>

<%= link_to "New product", new_store_product_path %>

<div id="products">
  <% @products.each do |product| %>
    <div>
      <%= link_to product.name, store_product_path(product) %>
    </div>
  <% end %>
</div>
```

このビューは`store`名前空間に移動したので、見出しの`<h1>`タグの相対的な訳文を参照できなくなっています。これを修正するために、`config/locales/en.yml`に以下の訳文を追加できます。

```yaml
en:
  hello: "Hello world"
  products:
    index:
      title: "Products"

  store:
    products:
      index:
        title: "Products"

  activerecord:
    attributes:
      user:
        password_challenge: "Current password"
```

`app/views/store/products/new.html.erb`ファイル内の"Cancel"リンクも`store`名前空間で更新する必要があります。

```erb
<h1>New product</h1>

<%= render "form", product: @product %>
<%= link_to "Cancel", store_products_path %>
```

`app/views/store/products/edit.html.erb`ファイルも同様に更新します。

```erb
<h1>Edit product</h1>

<%= render "form", product: @product %>
<%= link_to "Cancel", store_product_path(@product) %>
```

`app/views/store/products/show.html.erb`ファイルも以下のように更新します。

```erb
<p><%= link_to "Back", store_products_path %></p>

<section class="product">
  <%= image_tag @product.featured_image if @product.featured_image.attached? %>

  <section class="product-info">
    <% cache @product do %>
      <h1><%= @product.name %></h1>
      <%= @product.description %>
    <% end %>

    <%= link_to "View in Storefront", @product %>
    <%= link_to "Edit", edit_store_product_path(@product) %>
    <%= button_to "Delete", [ :store, @product ], method: :delete, data: { turbo_confirm: "Are you sure?" } %>
  </section>
</section>
```

これで、`show`アクションが以下のように更新されました。

- リンクで`store`名前空間が使われるようになった。
- "View in Storefront"リンクが追加され、管理者が製品の一般向け表示を手軽に確認できるようになった。
- 一般向けストアフロント以外では不要なパーシャルテンプレートを削除可能になった。

管理画面では`_inventory.html.erb`パーシャルが不要になったため、削除しましょう。

```bash
$ rm app/views/store/products/_inventory.html.erb
```

テストを追加する
------------

機能が正常に動作することを検証するため、テストをいくつか追加しましょう。

### 認証テストのヘルパーを追加する

このテストスイートでは、ユーザーをテスト内でサインインさせる必要があります。Railsの認証ジェネレータは認証用のヘルパーを含むように更新されていますが、認証ジェネレータがなかった時期にアプリケーションを作成した場合は、テストを書き始める前にこれらのファイルが存在することを確認しておきましょう。

`test/test_helpers/session_test_helper.rb`ファイルには以下の内容が含まれているはずです。このファイルが存在しない場合は、ファイルを作成します。

```ruby
module SessionTestHelper
  def sign_in_as(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies[:session_id] = cookie_jar[:session_id]
    end
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete(:session_id)
  end
end
```

`test/test_helper.rb`には以下のコードがあるはずです。ない場合は追加しておきましょう。

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    include SessionTestHelper

    # ワーカー数を指定してテストを並列実行する
    parallelize(workers: :number_of_processors)

    # test/fixtures/*.yml内のすべてのフィクスチャをアルファベット順でセットアップする
    fixtures :all

    # 全テスト共通で使われるヘルパーメソッドをここに追加する
  end
end
```

### サインアップ機能をテストする

サインアップに関してテストするべきことがいくつかあります。まずは、ページを表示するためのシンプルなテストから始めましょう。

`test/controllers/sign_ups_controller_test.rb`ファイルを以下の内容で作成します。

```ruby
require "test_helper"

class SignUpsControllerTest < ActionDispatch::IntegrationTest
  test "view sign up" do
    get sign_up_path
    assert_response :success
  end
end
```

このテストは、`/sign_up`にアクセスしたときに"200 OK"レスポンスが返されることを確認します。

テストを実行してパスするかどうかを確認しましょう。

```bash
$ bin/rails test test/controllers/sign_ups_controller_test.rb:4
Running 1 tests in a single process (parallelization threshold is 50)
Run options: --seed 5967

# Running:

.

Finished in 0.559107s, 1.7886 runs/s, 1.7886 assertions/s.
1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

次に、ユーザーをサインインさせてサインアップページにアクセスしてみましょう。この場合、ユーザーは既に認証済みなので、リダイレクトされるはずです。

以下のテストをファイルに追加します。

```ruby
test "view sign up when authenticated" do
  sign_in_as users(:one)
  get sign_up_path
  assert_redirected_to root_path
end
```

テストを再実行すると、このテストもパスするはずです。

次に、フォームに入力したときに新しいユーザーが作成されることを確認するテストを追加しましょう。

```ruby
test "successful sign up" do
  assert_difference "User.count" do
    post sign_up_path, params: { user: { first_name: "Example", last_name: "User", email_address: "example@user.org", password: "password", password_confirmation: "password" } }
    assert_redirected_to root_path
  end
end
```

このテストでは、`create`アクションをテストするためにPOSTリクエストでパラメータを送信する必要があります。

無効なデータを渡すとコントローラがエラーを返すことを確認することもテストしましょう。

```ruby
test "invalid sign up" do
  assert_no_difference "User.count" do
    post sign_up_path, params: { user: { email_address: "example@user.org", password: "password", password_confirmation: "password" } }
    assert_response :unprocessable_entity
  end
end
```

このテストではユーザー名を指定していないので、無効になるはずです。このリクエストは無効なので、レスポンスが"422 Unprocessable Entity"になるというアサーションが必要です。また、`User.count`の値が変わらないというアサーションによって、無効なリクエストでユーザーが作成されないことも確認できます。

次に追加する重要なテストは、サインアップに`admin`属性を渡せないことを確認するテストです。

```ruby
test "sign up ignores admin attribute" do
  assert_difference "User.count" do
    post sign_up_path, params: { user: { first_name: "Example", last_name: "User", email_address: "example@user.org", password: "password", password_confirmation: "password", admin: true } }
    assert_redirected_to root_path
  end
  refute User.find_by(email_address: "example@user.org").admin?
end
```

これは、先ほどの成功するサインアップと同じテストですが、`admin: true`を不正に設定しようとしている点が異なります。ユーザーが作成されたというアサーションに続いて、ユーザーが管理者「ではない」というアサーションも必要です。

### メールアドレスの変更機能をテストする

ユーザーのメールアドレス変更機能は複数のステップで構成されるため、これもテストしておくことが重要です。

まず、メールアアドレのｎ更新フォームがすべて正しく処理されることを確認するためのコントローラテストを作成しましょう。

`test/controllers/settings/emails_controller_test.rb`ファイルを以下の内容で作成します。

```ruby
require "test_helper"

class Settings::EmailsControllerTest < ActionDispatch::IntegrationTest
  test "validates current password" do
    user = users(:one)
    sign_in_as user
    patch settings_email_path, params: { user: { password_challenge: "invalid", unconfirmed_email: "new@example.org" } }
    assert_response :unprocessable_entity
    assert_nil user.reload.unconfirmed_email
    assert_no_emails
  end
end
```

1つ目のテストは、無効なパスワードチャレンジを含むフォーム送信をテストします。ここでは、レスポンスがエラーになることと、`unconfirmed_email`属性が変更されていないことを確認します。メールが送信されていないこともこのテストで確認できます。

次に、フォーム送信が成功した場合のテストを作成します。

```ruby
test "sends email confirmation on successful update" do
  user = users(:one)
  sign_in_as user
  patch settings_email_path, params: { user: { password_challenge: "password", unconfirmed_email: "new@example.org" } }
  assert_response :redirect
  assert_equal "new@example.org", user.reload.unconfirmed_email
  assert_enqueued_email_with UserMailer, :email_confirmation, params: { user: user }
end
```

このテストは、有効なパラメータを送信したときに、メールアドレスがデータベースに保存されることと、ユーザーがリダイレクトされ、確認メールが配信キューに登録されることを確認します。

これらのテストを実行して、すべてのテストがパスすることを確認しましょう。

```bash
$ bin/rails test test/controllers/settings/emails_controller_test.rb
Running 2 tests in a single process (parallelization threshold is 50)
Run options: --seed 31545

# Running:

..

Finished in 0.954590s, 2.0951 runs/s, 6.2854 assertions/s.
2 runs, 6 assertions, 0 failures, 0 errors, 0 skips
```

`Email::ConfirmationsController`のテストも必要です。メールアドレス更新の確認用トークンが期待通りバリデーションされ、メールアドレスの更新プロセスが正常に完了することを確認します。

`test/controllers/email/confirmations_controller_test.rb`ファイルを以下の内容で作成します。

```ruby
require "test_helper"

class Email::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "invalid tokens are ignored" do
    user = users(:one)
    previous_email = user.email_address
    user.update(unconfirmed_email: "new@example.org")
    get email_confirmation_path(token: "invalid")
    assert_equal "Invalid token.", flash[:alert]
    user.reload
    assert_equal previous_email, user.email_address
  end

  test "email is updated with a valid token" do
    user = users(:one)
    user.update(unconfirmed_email: "new@example.org")
    get email_confirmation_path(token: user.generate_token_for(:email_confirmation))
    assert_equal "Your email has been confirmed.", flash[:notice]
    user.reload
    assert_equal "new@example.org", user.email_address
    assert_nil user.unconfirmed_email
  end
end
```

1つ目のテストは、無効なトークンでメールアドレスの変更を確認しようとするシナリオをシミュレートします。エラーメッセージが表示されるというアサーションと、メールアドレスが変更されていないというアサーションを行っています。

2つ目のテストは、有効なトークンでメールアドレスの変更を確認するシナリオをシミュレートします。成功メッセージが表示されるというアサーションと、データベース内のメールアドレスが更新されているというアサーションを行っています。

`test/mailers/user_mailer_test.rb`ファイルを以下の内容で更新します。

```ruby
require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "email_confirmation" do
    user = users(:one)
    user.update(unconfirmed_email: "new@example.org")
    mail = UserMailer.with(user: user).email_confirmation
    assert_equal "Email confirmation", mail.subject
    assert_equal [ "new@example.org" ], mail.to
    assert_match "/email/confirmations/", mail.body.encoded
  end
end
```

このテストでは、ユーザーの`unconfirmed_email`属性が設定されていることを確認し、そのメールアドレスにメールが送信されることを確認します。メール本文に`/email/confirmations/`パスが含まれていることも確認します。これにより、ユーザーがクリックして新しいメールアドレスを確認するためのリンクがメールに含まれていることを確認できます。

### 「Settings」ナビゲーションをテストする

もう1つテストすべき領域は、設定ナビゲーションです。管理者に適切なリンクが表示され、通常のユーザーには表示されないことを確認したいと思います。

まず、`test/fixtures/users.yml`に管理者ユーザーのフィクスチャを作成し、通常ユーザーの名前も追加して、バリデーションにパスするようにします。

```yaml
<% password_digest = BCrypt::Password.create("password") %>

one:
  email_address: one@example.com
  password_digest: <%= password_digest %>
  first_name: User
  last_name: One

two:
  email_address: two@example.com
  password_digest: <%= password_digest %>
  first_name: User
  last_name: Two

admin:
  email_address: admin@example.com
  password_digest: <%= password_digest %>
  first_name: Admin
  last_name: User
  admin: true
```

続いて、このフィクスチャを使うテストを`test/integration/settings_test.rb`ファイルに作成します。

```ruby
require "test_helper"

class SettingsTest < ActionDispatch::IntegrationTest
  test "user settings nav" do
    sign_in_as users(:one)
    get settings_profile_path
    assert_dom "h4", "Account Settings"
    assert_not_dom "a", "Store Settings"
  end

  test "admin settings nav" do
    sign_in_as users(:admin)
    get settings_profile_path
    assert_dom "h4", "Account Settings"
    assert_dom "h4", "Store Settings"
  end
end
```

これらのテストによって、管理者のナビゲーションバーにだけストアの「Settings」を表示できることを確認できます。

以下のコマンドでこれらのテストを実行できます。

```bash
$ bin/rails test test/integration/settings_test.rb
```

一般ユーザーがProductsとUsersのストア「Settings」にアクセスできないことも確認しておきたいと思います。これらのテストも追加しましょう。

```ruby
test "regular user cannot access /store/products" do
  sign_in_as users(:one)
  get store_products_path
  assert_response :redirect
  assert_equal "You aren't allowed to do that.", flash[:alert]
end

test "regular user cannot access /store/users" do
  sign_in_as users(:one)
  get store_users_path
  assert_response :redirect
  assert_equal "You aren't allowed to do that.", flash[:alert]
end
```

これらのテストでは、管理者専用エリアに一般ユーザーがアクセスしようとすると、リダイレクトされてフラッシュメッセージが表示されることが確認されます。

最後に、管理者ユーザーが管理者専用エリアにアクセス可能であることを確認するテストを追加しましょう。

```ruby
test "admins can access /store/products" do
  sign_in_as users(:admin)
  get store_products_path
  assert_response :success
end

test "admins can access /store/users" do
  sign_in_as users(:admin)
  get store_users_path
  assert_response :success
end
```

テストを再実行して、すべてのテストがパスすることを確認します。

```bash
$ bin/rails test test/integration/settings_test.rb
Running 6 tests in a single process (parallelization threshold is 50)
Run options: --seed 33354

# Running:

......

Finished in 0.625542s, 9.5917 runs/s, 12.7889 assertions/s.
6 runs, 8 assertions, 0 failures, 0 errors, 0 skips
```

最後にテストスイート全体をもう一度実行して、すべてのテストがパスすることを確認します。

```bash
$ bin/rails test
Running 18 tests in a single process (parallelization threshold is 50)
Run options: --seed 38561

# Running:

..................

Finished in 0.915621s, 19.6588 runs/s, 51.3313 assertions/s.
18 runs, 47 assertions, 0 failures, 0 errors, 0 skips
```

素晴らしい！それではこれをproduction環境にデプロイしましょう。

production環境にデプロイする
-----------------------

[Railsをはじめよう](getting_started.html#kamalでproduction環境にデプロイする)ガイドでKamalをセットアップしているので、コードの変更をGitリポジトリにプッシュして、以下のコマンドを実行するだけでデプロイは完了します。

```bash
$ bin/kamal deploy
```

これで、storeアプリケーションの新しいコンテナがビルドされ、productionサーバーにデプロイされます。

### production環境で管理者アカウントを設定する

`User``atにｎr_readonly :admin`を追加した場合は、以下のようにdbconsoleでアカウントを更新する必要があります。

```bash
$ bin/kamal dbc
UPDATE users SET admin=true WHERE users.email='you@example.org';
.quit
```

あるいは、以下のようにRailsコンソールでアカウントを更新することも可能です。

```bash
$ bin/kamal console
irb> User.find_by(email: "you@example.org").update(admin: true)
```

これで、このアカウントを使ってproduction環境でStoreの「Settings」にアクセスできるようになりました。

今後の機能
-----------

以上ですべて完了しました！eコマースストアで「サインアップ」「アカウント管理」「製品とユーザーの管理用の管理者エリア」がサポートされるようになりました。

これらの機能を元にして、さらに以下のような機能も構築できます。

- 共有可能なウィッシュリストを追加する
- テストをさらに追加して、アプリケーションが正しく動作することを確認する
- 製品購入のための支払い機能を追加する

Happy building!

[全レベルユーザー向けのチュートリアル紹介ページ（英語）に戻る](https://rubyonrails.org/docs/tutorials)
