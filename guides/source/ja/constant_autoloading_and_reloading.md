


定数の自動読み込みと再読み込み
===================================

本書ではRailsの定数が自動読み込みおよび再読み込みされる仕組みについて説明します。

このガイドの内容:

* Rubyで使用される定数の重要な点
* `autoload_paths`について
* 定数が自動読み込みされる仕組み
* `require_dependency`について
* 定数が再読み込みされる仕組み
* 自動読み込みでよく発生する問題の解決方法

--------------------------------------------------------------------------------


はじめに
------------

Ruby on Railsでコードを書き換えると、開発者がサーバーを再起動しなくても、あたかも既にアプリケーションに読み込み済みであるかのように動作します。

通常のRubyプログラムのクラスであれば、依存関係のあるプログラムを明示的に読み込む必要があります。

```ruby
require 'application_controller'
require 'post'

class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

Rubyistとしての本能は、上のコードを見た瞬間にそこに冗長な部分があることを察知するでしょう。クラスが、それが保存されているファイル名と同じ名前で定義されるのであれば、どうにかしてそれらを自動的に読み込めないものでしょうか。依存するファイルを探索してその結果を保存しておけばよいのですが、こうした依存関係は何かと不安定です。

さらに、`Kernel#require`はファイルを一度しか読み込みませんが、読み込んだファイルが更新された時にサーバーを再起動せずに更新を反映できれば、開発はずっと楽になるでしょう。開発時には`Kernel#load`を利用し、本番では`Kernel#require`を都合よく利用できれば便利です。

そしてまさに、Ruby on Railsでは以下のように書くだけでこのような便利な機能を利用することができます。

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

本章ではこの機能の仕組みについて解説します。


定数更新
-------------------

多くのプログラミング言語において、定数はさほど重要な位置を占めていませんが、ことRubyにおいては定数に関する話題が非常に豊富です。

Ruby言語の定数についての解説は本ガイドの範疇を超えますので深入りはしませんが、定数に関してはいくつかの重要な点にスポットライトを当てたいと思います。以降の章を十分に理解することは、Railsにおける定数の自動読み込みと再読み込みを理解するための頼もしい武器となることでしょう。

### ネスト

クラスおよびモジュールの定義をネストすることで名前空間を作成できます。

```ruby
module XML
  class SAXParser
    # (1)
  end
end
```

ある場所における*ネスト*とは、ネストしたクラスおよびモジュールオブジェクトをネストの内側のものから順に並べたコレクションとなります(訳注: Ruby内のある場所のネストを調べるには`Module.nesting`を使用します)。前述の例における(1)の位置のネストは以下のようになります。

```ruby
[XML::SAXParser, XML]
```

ネストはクラスやモジュールの「オブジェクト」で構成されるという点を理解することが重要です。ネストはそれにアクセスするための定数とは何の関係もなく、ネストの名前とも関係ありません。

たとえば、以下の定義は前述の定義と似ています。

```ruby
class XML::SAXParser
  # (2)
end
```

(2)でネストを行った結果は異なります。

```ruby
[XML::SAXParser]
```

単体の`XML`はネストに含まれていません。

この例からわかるように、ある特定のネストに属するクラス名やモジュール名は、ネストの位置における名前空間と必ずしも相関していません。

さらに、両者は相関どころか互いに完全に独立しています。以下の例で考察してみましょう。

```ruby
module X::Y
  module A::B
    # (3)
  end
end
```

(3)の位置で行われるネストは、以下のように2つのモジュールオブジェクトで構成されます。

```ruby
[A::B, X::Y]
```

このネストは`A`で終わっていないだけでなく (そもそもこの`A`はネストに属してすらいません)、ネストに`X::Y`も含まれています。この`X::Y`と`A::B`は互いに独立しています。

このネストは、Rubyインタプリタによって維持されている内部スタックであり、以下のルールに従って変更されます。

* `class`キーワードに続けて記述されるクラスオブジェクトは、その内容が実行される時にスタックにプッシュされ、実行完了後にスタックからポップされる。

* `module`キーワードに続けて記述されるモジュールオブジェクトは、その内容が実行される時にスタックにプッシュされ、実行完了後にスタックからポップされる。

* 特異クラスは`class << object`でオープンされるときにスタックにプッシュされ、後でスタックからポップされる。

* `*_eval`で終わるメソッドが文字列を1つ引数に取って呼び出されると、そのレシーバの特異クラスはevalされたコードのネストにプッシュされる。

* `Kernel#load`によって解釈されるコードのトップレベルにあるネストは空になる。ただし`load`呼び出しが第2引数としてtrueという値を受け取る場合を除く。この値が指定されると、無名モジュールが新たに作成されてRubyによってスタックにプッシュされる。

ここで興味深いのは、ブロックがスタックに何の影響も与えないという事実です。特に、`Class.new`や`Module.new`に渡される可能性のあるブロックは、`new`メソッドによって定義されるクラスやモジュールをネストにプッシュしません。この点が、ブロックを使用せずに何らかの形でクラスやモジュールを定義する場合と異なる点の一つです。

`Module.nesting`を使用することで、任意の位置にあるネストを検査 (inspect) することができます。

### クラスやモジュールの定義とは定数への代入のこと

以下のスニペットを実行するとクラスが (再オープンではなく) 新規作成されるとします。

```ruby
class C
end
```

Rubyは`Object`に`C`という定数を作成し、その定数にクラスオブジェクトを保存します。このクラスインスタンスの名前は"C"という文字列であり、この定数の名前から付けられたものです。

すなわち、

```ruby
class Project < ActiveRecord::Base
end
```

上のコードは定数代入 (constant assignment) を行います。これは以下のコードと同等です。

```ruby
Project = Class.new(ActiveRecord::Base)
```

このとき、以下のようにクラスの名前は副作用として設定されます。

```ruby
Project.name # => "Project"
```

この動作を実現するために、定数代入には1つの特殊なルールが設定されています。代入されるオブジェクトが無名のクラスまたはモジュールである場合、Rubyはそれらのオブジェクトの名前をその定数の名前から引用して命名します。

INFO: 無名クラスや無名モジュールにひとたび名前が与えられた後は、定数とインスタンスで何が起きるかは問題ではありません。たとえば、定数を削除することもできますし、クラスオブジェクトを別の定数に代入したりどの定数にも保存しないでおくこともできます。名前はいったん設定された後は変化しなくなります。

`module`キーワードを指定して以下のようにモジュールを作成する場合も、クラスの場合と同様に考えることができます。

```ruby
module Admin
end
```

上のコードは定数代入を行います。これは以下のコードと同等です。

```ruby
Admin = Module.new
```

このとき、以下のようにモジュールの名前は副作用として設定されます。

```ruby
Admin.name # => "Admin"
```

WARNING: `Class.new`や`Module.new`に渡されるブロックの実行コンテキストは、`class`および`module`キーワードを使用する定義の本文の実行コンテキストと完全に同等ではないことがあります。しかし定数代入はどちらのイディオムを使用した場合にも同様に行われます。

何かが非公式に "`String`クラス" と呼ばれる場合、その本当の意味はこういうことです。"`String`クラス" とは、`Object`という定数があり、その中にクラスオブジェクトが保存されていて、さらにその中に"String"と呼ばれる定数があり、さらにその中に保存されているクラスオブジェクトのことなのです。そうでなければ、`String`はRubyのありふれた定数であり、解決アルゴリズムなどそれに関連するあらゆるものがこの`String`という定数に適用されます。

コントローラについても同様に考えることができます。

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

上のコードの`Post`はクラスのための文法ではありません。そうではなく、`Post`はRubyにおける通常の定数です。何も問題がなければ、この定数は`all`メソッドをもつオブジェクトとして評価されます。

ここまで*定数*の自動読み込みについて詳細に解説したのはこのような理由からです。Railsは定数を必要に応じて読み込む機能を持っています。

### 定数はモジュールに保存される

Rubyの定数は、まったく文字通りに「モジュールに属します」。クラスとモジュールには定数テーブルがあります。これはハッシュテーブルのようなものと考えることができます。

これがどういうことなのかを十分理解するために、ひとつ例を示して分析してみましょう。"この`String`クラス"のようなあいまいな表現は説明する側にとっては便利ですが、ここでは教育的な見地から厳密に説明することにします。

以下のモジュール定義について考察してみましょう。

```ruby
module Colors
  RED = '0xff0000'
end
```

最初に`module`キーワードが処理されると、Rubyインタプリタは`Object`定数に保存されているクラスオブジェクトの定数テーブルに新しいエントリを1つ作成します。
このエントリは、"Colors"という名前と、新しく作られたモジュールオブジェクトを関連付けます。
さらに、Rubyインタプリタは新しいモジュールオブジェクトの名前を"Colors"という文字列として設定します。

後に、このモジュール定義の本体がRubyインタプリタによって解釈されると、`Colors`定数の中に保存されたモジュールオブジェクトの定数テーブルの中に新しいエントリが1つ作成されます。このエントリは、"RED"という名前を"0xff0000"という文字列に対応付けます。

特にこの`Colors::RED`は、他のクラスオブジェクトやモジュールオブジェクトの中にあるかもしれない他の`RED`定数とは何の関連もないことにご注意ください。もし仮に他の`RED`定数がたまたま存在しているとしたら、それは独自の定数テーブルの中に異なるエントリとして存在するはずです。

前述の段落の説明を読む際には、クラスオブジェクト、モジュールオブジェクト、定数名、定数テーブルに関連付けられている値オブジェクトをそれぞれ混同しないように十分注意してください。

### 解決アルゴリズム

#### 相対定数を解決するアルゴリズム

ネストが空でなければその最初の要素、空の場合には`Object`を、コードの任意の場所での*cref*というようにしましょう (訳注: crefはRuby内部におけるクラス参照 (class reference) の略であり、Rubyの定数が持つ暗黙のコンテキストです -- [関連記事](http://yugui.jp/articles/846) )。

詳細についてはここでは述べませんが、相対的な定数参照を解決するアルゴリズムは以下のようになります。

1. ネストが存在する場合、この定数はそのネストの要素の中で順に探索される。それらの要素の先祖は探索されない (訳注: 本章で言う先祖 (ancestors) とは[クラス、モジュールのスーパークラスとインクルードしているモジュール](http://docs.ruby-lang.org/ja/2.2.0/method/Module/i/ancestors.html)のことです)。

2. 見つからない場合は、crefの先祖チェーン (継承チェーン) を探索する。

3. 見つからない場合、crefに対して`const_missing`が呼び出される。`const_missing`のデフォルトの実装は`NameError`を発生するが、これはオーバーライド可能。

Railsの自動読み込みは**このアルゴリズムをエミュレートしているわけではない**ことにご注意ください。ただし探索の開始ポイントは、自動読み込みされる定数の名前と、cref自身です。詳細については[相対参照](#%E8%87%AA%E5%8B%95%E8%AA%AD%E3%81%BF%E8%BE%BC%E3%81%BF%E3%81%AE%E3%82%A2%E3%83%AB%E3%82%B4%E3%83%AA%E3%82%BA%E3%83%A0-%E7%9B%B8%E5%AF%BE%E5%8F%82%E7%85%A7)を参照してください。

#### 修飾済み定数を解決するアルゴリズム

修飾済み (qualified) 定数は以下のようなものです。

```ruby
Billing::Invoice
```

`Billing::Invoice`には2つの定数が含まれています。最初の`Billing`の方は相対的な定数であり、直前のセクションで解説したアルゴリズムに基いて解決されます。

INFO: `::Billing::Invoice`のように先頭にコロンを2つ置くことで、最初のセグメントを相対から絶対に変えることができます。このようにすると、この`Billing`はトップレベルの定数としてのみ参照されるようになります。

2番目の`Invoice`定数の方は`Billing`で修飾されています。この定数の解決方法についてはこの後で説明します。ここで、修飾する側のクラスやモジュールオブジェクト (上の例で言う`Billing`) を*親(parent)*と定義します。修飾済み定数を解決するアルゴリズムは以下のようになります。

1. この定数はその親と先祖の中から探索される。

2. 探索の結果何も見つからない場合、親の`const_missing`が呼び出される。`const_missing`のデフォルトの実装は`NameError`を発生するが、これはオーバーライド可能。

見てのとおり、この探索アルゴリズムは相対定数の場合よりもシンプルです。特に、ネストが何の影響も与えていない点にご注意ください。また、モジュールは特別扱いされておらず、モジュール自身またはモジュールの先祖のどちらにも定数がない場合には`Object`は**チェックされない**点にもご注意ください。

Railsの自動読み込みは**このアルゴリズムをエミュレートしているわけではない**ことにご注意ください。ただし探索の開始ポイントは、自動読み込みされる定数の名前と、その親です。詳細については[修飾済み参照](#%E8%87%AA%E5%8B%95%E8%AA%AD%E3%81%BF%E8%BE%BC%E3%81%BF%E3%81%AE%E3%82%A2%E3%83%AB%E3%82%B4%E3%83%AA%E3%82%BA%E3%83%A0-%E4%BF%AE%E9%A3%BE%E6%B8%88%E3%81%BF%E5%8F%82%E7%85%A7)を参照してください。


用語説明
----------

### 親の名前空間

定数パスで与えられた文字列を使用して、*親の名前空間* (parent namespace) が定義されます。親の名前空間は、定数パスからその右端のセグメントのみを除去した文字列になります。

たとえば、"A::B::C" という文字列の親の名前空間は "A::B" という文字列となり、"A::B" という文字列の親の名前空間は "A" となり、"A" という文字列の親の名前空間は "" となります。

しかし、クラスやモジュールについて考察する場合、親の名前空間の解釈にトリッキーな点が生じるので注意が必要です。例として、"A::B"という名前を持つモジュールMについて考察してみましょう。

* 親の名前空間 "A" は、与えられた位置におけるネストの状態を反映していない可能性がある。

* `A`という定数は既に存在しなくなっている可能性がある。この定数は何らかのコードによって`Object`から削除されているかもしれない。

* たとえ`A`という定数が存在するとしても、かつて`A`という名前を持っていたクラスまたはモジュールは既に存在しなくなっている可能性がある。たとえば、定数が1つ削除された後に別の定数代入 (constant assignment) が行われたとすると、一般的にはそれは別のオブジェクトを指していると考えるべき。

* そのような状況で`A`という同じ名前の定数が再度代入されると、その`A`は同じく"A"という名前を持つ別の新しいクラスまたはモジュールを指す可能性すらありうる。

* 上述のシナリオが発生した場合、`A::B`という名前でMというモジュールを参照することはできなくなってしまうが、Mというモジュールオブジェクト自身は"A::B"という名前を持ったまま、削除されることもなくどこかに生きている可能性がある。

この「親の名前空間」は自動読み込みアルゴリズムの中核となるアイディアであり、アルゴリズム開発上の意図を直感的に説明するのに役立ちますが、このメタファーだけでは説明しきれない部分が多くあります。エッジケースでどのようなことが起きるかを十分理解するために、本章で説明されている「親の名前空間」という概念とその意味を正確に理解したうえで、親の名前空間を常に意識しながら読み進めてください。

### 読み込みのメカニズム

`config.cache_classes`がfalseに設定されていると、`Kernel#load`を使用して読み込みが行われます。これはdevelopmentモードにおけるデフォルトの設定です。他方、`Kernel#require`を使用する読み込みは、productionモードにおけるデフォルトの設定です。

[定数の再読み込み](#定数の再読み込み)が有効になっていると、`Kernel#load`が使用され、ファイルを繰り返し読み込めるようになります。

本章では「読み込み」(load)という言葉を、指定されたファイルがRailsによって解釈されるという程度の緩やかな意味で使用していますが、実際のメカニズムとしてはフラグに応じて`Kernel#load`や`Kernel#require`が使用されます。


自動読み込みが可能となる状況
------------------------

Railsは、そのための環境が設定されていれば常に自動読み込みを行います。たとえば、以下の`runner`コマンドを実行すると自動読み込みが行われます。

```
$ bin/rails runner 'p User.column_names'
["id", "email", "created_at", "updated_at"]
```

この場合、コンソール、テストスイート、アプリケーションのすべてについて自動読み込みが行われます。

productionモードで起動された場合は、デフォルトでファイルの事前一括読み込み (eager loading) が行われるため、developmentモードのような自動読み込みはほとんど発生しません。ただし、事前一括読み込みにおいても自動読み込みが発生することがあります。

以下の例で考察してみましょう。

```ruby
class BeachHouse < House
end
```

`app/models/beach_house.rb`は事前一括読み込みされているにもかかわらず`House`が見つからなかった場合、Railsはこれについて自動読み込みを行います。


autoload_paths
--------------

これについてはご存じの方も多いことでしょう。以下のように`require`で相対的なファイル名を指定したとします。

```ruby
require 'erb'
```

このとき、Rubyは`$LOAD_PATH`で指定されているディレクトリ内でこのファイルを探索します。具体的には、Rubyは指定されたすべてのディレクトリについて反復処理を行い、それらの中に"erb.rb"や"erb.so"や"erb.o"や"erb.dll"などの名前を持つファイルがあるかどうかを調べます。いずれかの名前を持つファイルがディレクトリで見つかれば、Rubyインタプリタはそのファイルを読み込み、探索をそこで終了します。見つからない場合はリストにある次のディレクトリで同じ処理を繰り返します。リストをすべて探索しても見つからない場合は`LoadError`が発生します。

ここから定数の自動読み込みについて詳細を説明しますが、その中核となるアイディアは次のとおりです。たとえば`Post`のような定数がコード中に出現した時点では未定義であったとします。このとき`app/models`ディレクトリに`post.rb`というファイルがあれば、Railsはこの定数を探索・評価し、その結果`Post`という定数を「副作用として」定義します。

ところで、Railsには`post.rb`のようなファイルを探索する`$LOAD_PATH`に似た、ディレクトリのコレクションがあります。このコレクションは`autoload_paths`と呼ばれており、デフォルトで以下が含まれます。

* アプリケーションとエンジンの`app`ディレクトリ以下にあるすべてのサブディレクトリ。`app/controllers`などが対象。`app`以下に置かれる`app/workers`などのカスタムディレクトリはすべて`autoload_paths`に自動的に属するので、デフォルトのディレクトリとする必要はない。

* アプリケーションとエンジンのすべての`app/*/concerns`第2サブディレクトリ。

* `test/mailers/previews`ディレクトリ。

このコレクションは`config.autoload_paths`で設定できます。たとえば`lib`ディレクトリは以前はコレクションに含まれていましたが、現在は含まれていません。必要であれば、`config/application.rb`にあえて以下のコードを追加して (オプトイン)、`lib`ディレクトリをautoload_pathsに追加することもできます。

```ruby
config.autoload_paths += "#{Rails.root}/lib"
```

`autoload_paths`の値を検査することもできます。生成したRailsアプリケーションでは以下のようになります (ただし編集済み)。

```
$ bin/rails r 'puts ActiveSupport::Dependencies.autoload_paths'
.../app/assets
.../app/controllers
.../app/helpers
.../app/mailers
.../app/models
.../app/controllers/concerns
.../app/models/concerns
.../test/mailers/previews
```

INFO: `autoload_paths`は初期化中に算出され、キャッシュされます。ディレクトリ構造が少しでも変更された場合、変更を反映するにはアプリケーションを再起動する必要があります。


自動読み込みのアルゴリズム
----------------------

### 相対参照

定数の相対的な参照は、以下のようにさまざまな場所で行われます。

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

上のコードで使用されている3つの定数はすべて相対参照されています。

#### `class`および`module`キーワードの後に置かれる定数

Rubyは`class`や`module`キーワードの後ろに置かれる定数を探索します。その目的は、それらのクラスやモジュールがその場所で初めて作成されるのか、再度オープンされるのかを確認することです。

その時点で定数が未定義である場合、Rubyは定数が見つからないとは見なさないので、自動読み込みはトリガーされません。

前述の例で言うと、ファイルがRubyインタプリタによって解釈される時点で`PostsController`が定義されていない場合、Railsの自動読み込みはトリガーされず、Rubyは単にコントローラを定義します。

#### トップレベルの定数

逆に、`ApplicationController`がそれまでに出現していなかった場合、この定数は「見つからない」ものと見なされ、Railsによって自動読み込みがトリガーされます。

Railsは、`ApplicationController`を読み込むために`autoload_paths`にあるパスを順に処理します。最初に`app/assets/application_controller.rb`が存在するかどうかを確認します。見つからない場合 (これが通常です)、次のパスで`app/controllers/application_controller.rb`の探索を続行します。

見つかったファイルで`ApplicationController`が定義されていればOKです。定義されていない場合は`LoadError`が発生します。

```
unable to autoload constant ApplicationController, expected <application_controller.rbへのフルパス> to define it (LoadError)
```

INFO: Railsでは、自動読み込みされた定数の値がクラスオブジェクトやモジュールオブジェクトである必要はありません。たとえば、`app/models/max_clients.rb`というファイルで`MAX_CLIENTS = 100`と定義されている場合、`MAX_CLIENTS`の自動読み込みは問題なく行われます。

#### 名前空間

`ApplicationController`の自動読み込みは、それが行われる箇所のネストが空であるため、`autoload_paths`のディレクトリの下で直接行われているように見えます。`Post`の状況はこれとは異なります。その行におけるネストは`[PostsController]`であり、名前空間のサポートが効力を発揮し始めます。

基本的な考え方を以下に示します。

```ruby
module Admin
  class BaseController < ApplicationController
    @@all_roles = Role.all
  end
end
```

`Role`を自動読み込みするにあたり、`Role`が定義済みであるかどうかを自身あるいは親の名前空間でひとつずつチェックします。つまり、概念上は自動読み込みのいずれかを以下の順で行いたいわけです。

```
Admin::BaseController::Role
Admin::Role
Role
```

ここが肝心です。これを行なうために、Railsは`autoload_paths`のパスをファイル名順で以下のように探索します。

```
admin/base_controller/role.rb
admin/role.rb
role.rb
```

探索対象となるその他の標準的なディレクトリについては後述します。

INFO: `'Constant::Name'.underscore`は、`Constant::Name`が定義されていると期待されているファイルへの相対パスを返します。このファイル名には拡張子は含まれません。

Railsが`Post`定数をどのようにして前述の`PostsController`で自動読み込みするのかを詳しく見てみましょう。このアプリケーションには`app/models/post.rb`に`Post`モデルがあるとします。

最初に、`autoload_paths`のパスの中に`posts_controller/post.rb`が見つかるかどうかをチェックします。

```
app/assets/posts_controller/post.rb
app/controllers/posts_controller/post.rb
app/helpers/posts_controller/post.rb
...
test/mailers/previews/posts_controller/post.rb
```

この探索は失敗に終わるので、今度はディレクトリの有無を探索します。その理由については[次のセクション](#自動モジュール)で説明します。

```
app/assets/posts_controller/post
app/controllers/posts_controller/post
app/helpers/posts_controller/post
...
test/mailers/previews/posts_controller/post
```

これらの探索がすべて失敗すると、Railsは親の名前空間で探索を続行します。この例の場合、親はトップレベルしかありません。

```
app/assets/post.rb
app/controllers/post.rb
app/helpers/post.rb
app/mailers/post.rb
app/models/post.rb
```

やっとマッチするファイル`app/models/post.rb`が見つかりました。探索はここで終了し、ファイルが読み込まれます。`Post`がこのファイルで実際に定義されていればすべてOKです。定義されていない場合は`LoadError`が発生します。

### 修飾済み参照

修飾済み (qualified) 定数が見つからない場合、この定数は親の名前空間では探索されません。しかしここで注意すべき点がひとつあります。定数が見つからない場合、Railsはそのトリガーが相対的な参照であるか、修飾済み参照であるかを判定できなくなります。

以下の例について考察してみましょう。

```ruby
module Admin
  User
end
```

以下についても考察します。

```ruby
Admin::User
```

`User`が見つからなければ、上のどちらの場合にも、Railsは "User" という定数が "Admin" というモジュールの中にはないということだけを認識します。

この`User`がトップレベルにあるとすると、1番目の例はRubyによって解決されますが2番目の例は解決されません。Railsは、一般にRubyの定数解決アルゴリズムをエミュレートしませんが、このような場合には以下のヒューリスティックを利用して解決を図ります。

> 見つからない定数がそのクラスまたはモジュールの親の名前空間にもない場合、Railsはこの定数を相対参照であると仮定する。そうでない場合は修飾済み参照であると仮定する。

たとえば、以下のコードが自動読み込みを行い、

```ruby
Admin::User
```

かつ`User`定数が`Object`に既にある場合、以下のコードでは同じ状況になりません。

```ruby
module Admin
  User
end
```

そうでなければRubyは`User`を解決でき、そもそも最初の位置で自動読み込みは行われないはずです。この場合Railsはこの定数が修飾済み参照であると仮定し、`admin/user.rb`ファイルと`admin/user`ディレクトリが唯一の正当なオプションであるとみなします。

そのネストがすべての親名前空間にそれぞれマッチし、かつそのルールを適用させる定数の存在がその時点でRubyに認識されていれば、この方法は実用上機能します。

しかし、自動読み込みは要求に応じて発生するものです。その時点でたまたまトップレベルの`User`が読み込まれていなければ、Railsはこのヒューリスティックに従って定数を相対参照であると仮定します。

このような名前の競合は実際にはめったに発生しませんが、もし発生した場合は、`require_dependency`を使用して、競合の発生する場所でこのヒューリスティックを発動する必要のある定数が定義されるようにできます。

### 自動モジュール

モジュールがひとつの名前空間のように振る舞う場合、Railsアプリケーションではそのモジュールのためのファイルを定義する必要はありません。その名前空間にマッチするディレクトリがあれば十分です。

あるRailsアプリケーションに管理機能があり、そのためのコントローラが`app/controllers/admin`に保存されているとします。この`Admin`モジュールが読み込まれていない状態で`Admin::UsersController`へのアクセスが発生する場合は、Railsは最初に`Admin`という定数を自動読み込みしておく必要があります。

`admin.rb`というファイルが`autoload_paths`のパスに含まれている場合は、Railsによって読み込まれます。しかしそのようなファイルが見つからず、`admin`というディレクトリが見つかった場合は、Railsによって空のモジュールがひとつ作成され、`Admin`定数にその場で代入されます。

### 一般的な手順

相対参照は、それらがヒットしたcrefからは見つからないと報告されます。修飾済み参照はその親からは見つからないと報告されます。(*cref*の定義については本章の[相対定数を解決するアルゴリズム](#相対定数を解決するアルゴリズム)を、*parent*の定義については同じく[修飾済み定数を解決するアルゴリズム](#修飾済み定数を解決するアルゴリズム)を参照してください)

定数`C`を任意の状況で自動読み込みする手順を擬似言語で表現すると以下のようになります。 

```
if「定数Cが見つからないクラスまたはモジュール」がオブジェクトである
  let ns = ''
else
  let M = 定数Cが見つからないクラスまたはモジュール

  if Mが無名である
    let ns = ''
  else
    let ns = M.name
  end
end

loop do
  # 正規のファイルを探索する
  for dir in autoload_paths
    if "#{dir}/#{ns.underscore}/c.rb"ファイルが存在する
      load/require "#{dir}/#{ns.underscore}/c.rb"

      if 定数Cが定義済みである
        return
      else
        raise LoadError
      end
    end
  end

  # 自動モジュールを探索する
  for dir in autoload_paths
    if "#{dir}/#{ns.underscore}/c"ディレクトリが存在する
      if nsが空文字列である
        let C = Module.new in Object and return
      else
        let C = Module.new in ns.constantize and return
      end
    end
  end

  if nsが空である
    # 定数が見つからないままトップレベルに到着
    raise NameError
  else
    if Cが親の名前空間のどこかに存在する
      # 修飾済み定数のヒューリスティック
      raise NameError
    else
      # 親の名前空間で探索を再試行する
      let ns = nsの親の名前空間 and retry
    end
  end
end
```


require_dependency
------------------

定数の自動読み込みは必要に応じて自動的に行なわれるので、利用の際に定義済みである定数もあれば自動読み込みをトリガーする定数もあり、その動作は一定ではありません。自動読み込みは実行パスに依存しますが、実行パスはアプリケーションの実行中に変わることもありますのでやはり一定ではありません。

しかし、こうした定数の動作を確定させたくなることもしばしばあります。特定のコードを実行する時にそこにある定数が既知となるようにし、自動読み込みが発生しないようにできないものでしょうか。このような場合には`require_dependency`を使用します。これはその時点での[読み込みのメカニズム](#読み込みのメカニズム)を使用してファイルを読み込むことができ、必要に応じてそのファイルで定義されている定数をあたかも事前に読み込み済みであるかのように追跡することもできます。

`require_dependency`が必要になることはめったにありませんが、[自動読み込みとSTI](#%E8%87%AA%E5%8B%95%E8%AA%AD%E3%81%BF%E8%BE%BC%E3%81%BF%E3%81%A8sti)や[定数がトリガーされない場合](#定数がトリガーされない場合)でいくつかの実例を参照できます。

WARNING: `require_dependency`は自動読み込みと異なり、そのファイルで特定の定数が定義されていることを前提としません。この動作に依存するのはよくありませんが、ファイルと定数のパスは一致する必要があります。


定数の再読み込み
------------------

`config.cache_classes`がfalseの場合、Railsは自動読み込み済みの定数を再読み込みできるようになります。

たとえば、Railsのコンソールセッションを開いている状態で、いくつかのファイルがバックグラウンドで更新された場合、`reload!`コマンドを使用して定数を再読み込みできます。

```
> reload!
```

アプリケーションの実行中に、関連するロジックが変更されると、再読み込みが行われます。これを実現するために、Railsでは以下のさまざまな要素を監視しています。

* `config/routes.rb`

* ロケール

* `autoload_paths`以下のパスにあるRubyファイル

* `db/schema.rb`および`db/structure.sql`ファイル

これらのいずれかで変更が発生すると、ミドルウェアが変更を検出してコードを再読み込みします。

自動読み込みされた定数は、自動読み込みのインフラによって監視されます。再読み込みの具体的な実装では、`Module#remove_const`メソッドを呼び出して関連するクラスとモジュールをいったんすべて削除します。これにより、そのコードが実行されるとそれらの定数が再び未知の状態になり、必要に応じてファイルが再読み込みされます。

INFO: この動作は「オール・オア・ナッシング」です。Railsのクラスやモジュールの間にはきわめて微妙な依存関係があるため、変更が生じたクラスやモジュールだけを部分的に再読み込みすることはありません。クラスやモジュールは、変更が検出されるたびにすべてクリーンアップされます。


Module#autoloadが関与しない場合
------------------------------

`Module#autoload`は定数の遅延読み込み機能を提供します。この機能はRubyの定数探索アルゴリズムや動的定数APIなどと完全に統合されています。この動作はきわめて透過的です。

Rails内部では、ブートプロセス以後の作業を可能な限り遅延するためにこの機能が広く使用されています。ただし、Railsの定数自動読み込みでは`Module#autoload`を使用して実装されているわけでは**ありません**。

実装で`Module#autoload`を使用するのであれば、たとえばアプリケーションのツリーをすべてスキャンし、既存のファイル名と従来の定数名を関連付けるために`autoload`を呼び出すという方法が考えられます。

Railsでこのような実装を避けているのにはいくつかの理由があります。

たとえば、`Module#autoload`は`require`を使用するファイル読み込みしか行えないため、再読み込みには利用できないことがあります。しかも、このモジュールの内部では`Kernel#require`とは別の`require`が使用されています。

そのため、このモジュールではファイルが削除された場合にその宣言を削除する方法が提供されていません。定数を`Module#remove_const`で削除すると、以後`autoload`がトリガーされなくなってしまいます。また、このモジュールでは修飾名がサポートされていません。アプリケーションのツリーをスキャンして個別の`autoload`呼び出しをインストールする際に名前空間を解釈する必要がありますが、それらのファイルの定数参照がその時点でまだ構成されていない可能性があります。

`Module#autoload`を使用して素直に自動読み込みを実装できればよいのですが、上述のとおり現時点では不可能です。実際にはRailsの定数自動読み込みは`Module#const_missing`を使用して実装されています。そのような独自の用法がある理由は本章で述べているとおりです。


よくある落とし穴
--------------

### ネストと修飾済み定数

以下の2つについて考察してみましょう。

```ruby
module Admin
  class UsersController < ApplicationController
    def index
      @users = User.all
    end
  end
end
```

および

```ruby
class Admin::UsersController < ApplicationController
  def index
    @users = User.all
  end
end
```

Rubyは`User`を解決するために、1番目の例では`Admin`をチェックしますが、2番目の例はネストに属していないので`Admin`をチェックしません。([ネスト](#ネスト)および[解決アルゴリズム](#解決アルゴリズム)を参照)

残念ながら、Railsの自動読み込みはこの定数が見つからない箇所でネストが発生しているかどうかを認識しないので、通常のRubyと同じように振る舞うことができません。特に`Admin::User`はどちらの場合にも自動読み込みされます。

`class`キーワードや`module`キーワードの修飾済み定数は自動読み込みのいくつかのケースで動作することもありますが、修飾済み定数よりも以下のように相対定数を使用することをお勧めします。

```ruby
module Admin
  class UsersController < ApplicationController
    def index
      @users = User.all
    end
  end
end
```

### 自動読み込みとSTI

単一テーブル継承 (STI: Single Table Inheritance) はActive Recordの機能のひとつであり、モデルの階層構造を1つのテーブルに保存することができます。このようなモデルのAPIは階層構造を認識し、よく使われる要素がそこにカプセル化されます。たとえば以下のクラスがあるとします。

```ruby
# app/models/polygon.rb
class Polygon < ActiveRecord::Base
end

# app/models/triangle.rb
class Triangle < Polygon
end

# app/models/rectangle.rb
class Rectangle < Polygon
end
```

`Triangle.create`は三角形を表す行をひとつ作成し、`Rectangle.create`は四角形を表す行をひとつ作成します。`id`が既存レコードのIDであれば、`Polygon.find(id)`は正しい種類のオブジェクトを返します。

コレクションに対して実行されるメソッドは、階層構造も認識します。たとえば、三角形と四角形はどちらも多角形 (polygon) に含まれるため、`Polygon.all`はテーブル内のすべてのレコードを返します。Active Recordが返す結果セットでは、結果ごとに対応するクラスのインスタンスを返すように配慮されています。

種類は必要に応じて自動読み込みされます。たとえば、`Polygon.first`の結果が四角形 (rectangle) であり、`Rectangle`がその時点で読み込まれていなければ、Active Recordによって`Rectangle`が読み込まれ、そのレコードは正しくインスタンス化されます。

ここまでは何の問題もありません。しかし、ルートクラスに基づいたクエリではなく、何らかのサブクラスを使用しなければならない場合には事情が異なってきます。

`Polygon`に対して操作を行なうのであれば、テーブル内のすべてのエントリはpolygonとして定義されているので、どの子孫についても特別な配慮は必要はありません。しかし`Polygon`のサブクラスに対して操作を行う場合、Active Recordが探索しようとしている種類をそのサブクラスで列挙可能である必要があります。以下の例で考察してみましょう。

以下のように、取得する種類の制限をクエリに加えると、`Rectangle.all`はrectangleだけを読み込みます。

```sql
SELECT "polygons".* FROM "polygons"
WHERE "polygons"."type" IN ("Rectangle")
```

今度は`Rectangle`のサブクラスを導入してみましょう。

```ruby
# app/models/square.rb
class Square < Rectangle
end
```

`Rectangle.all`は四角形と正方形の**両方**を返します。

```sql
SELECT "polygons".* FROM "polygons"
WHERE "polygons"."type" IN ("Rectangle", "Square")
```

ただしここで注意が必要です。Active Recordは`Square`クラスの存在をいったいどのようにして認識しているのでしょうか。

`app/models/square.rb`というファイルが存在して`Square`クラスがその中で定義されていたとしても、クラス内のコードがその時点で利用されたことがなかった場合は`Rectangle.all`によって以下のクエリが発行されます。

```sql
SELECT "polygons".* FROM "polygons"
WHERE "polygons"."type" IN ("Rectangle")
```

これはバグではありません。`Rectangle`クラスのその時点で*既知*である子孫はクエリにすべて含まれています。

コードの実行順序にかかわらず常に期待どおりに動作させる手段として、ルートクラスが定義されているファイルの最終行で、ツリーの末端 (leaf) を明示的に読み込むという方法があります。

```ruby
# app/models/polygon.rb
class Polygon < ActiveRecord::Base
end
require_dependency ‘square’
```

この方法で明示的に読み込む必要があるのは、**孫またはそれ以下**のleafだけで十分です。直下のサブクラスである子については事前読み込みは不要です。階層構造が子よりも深い場合、階層の途中にあるクラスの定義で定数がスーパークラスとして記述されているので、途中のクラスは再帰的に自動読み込みされます。

### 自動読み込みと`require`

自動読み込みされる定数を定義するファイルは`require`すべきではありません。

```ruby
require 'user' # これを行ってはならない

class UsersController < ApplicationController
  ...
end
```

これはdevelopmentモードで以下の2つの落とし穴の原因となる可能性があります。

1. この`require`が実行されるより前に`User`が自動読み込みされると、`$LOADED_FEATURES`が`load`によって更新されないので、`app/models/user.rb`が再度実行されてしまいます。

2. この`require`が最初に実行されると、Railsは`User`を自動読み込み済み定数としてマーキングしないので、`app/models/user.rb`の変更は再読み込みされなくなってしまいます。

フローに従って、「常に」定数の自動読み込みを使用してください。自動読み込みと`require`は決して併用してはいけません。やむを得ない事情から、ファイルに特定のファイルをどうしても読み込んでおきたい場合は、最後の手段として、`require_dependency`を使用して定数の自動読み込みと調和させてください。このオプションが実際に必要になることはほぼないはずです。

もちろん、通常のサードパーティのライブラリについては、自動読み込みされるファイルの中で`require`で読み込んでも問題ありません。Railsはサードパーティのライブラリの定数を区別するので、これらは自動読み込みの対象としてマークされません。

### 自動読み込みとイニシャライザ

`config/initializers/set_auth_service.rb`で以下の代入を行った場合について考察してみましょう。

```ruby
AUTH_SERVICE = if Rails.env.production?
  RealAuthService
else
  MockedAuthService
end
```

この設定の目的は、`AUTH_SERVICE`で示される環境に対応するクラスをRailsアプリケーションから使用できるようにすることです。developmentモードでは、イニシャライザ実行時に`MockedAuthService`が自動読み込みされます。ここで、アプリケーションでいくつかのリクエストを処理した後、実装に変更を加え、再度アプリケーションにアクセスしたとしましょう。
驚くことに、変更したはずの実装が反映されていません。これはどういうことなのでしょう。

[前述](#定数の再読み込み)のとおり、自動読み込みされた定数はRailsによって削除されるのですが、`AUTH_SERVICE`には元のクラスオブジェクトが保存されています。このオブジェクトは最新の状態ではなくなっており、元の定数を使用してアクセスすることはできなくなっていますが、完全に機能します。

以下のコードはこの状況をまとめたものです。

```ruby
class C
  def quack
    'quack!'
  end
end

X = C
Object.instance_eval { remove_const(:C) }
X.new.quack # => quack!
X.name      # => C
C           # => uninitialized constant C (NameError)
```

こうした理由から、Railsアプリケーションの初期化時に定数を自動読み込みするのはよいアイディアとは言えません。

上のような場合には、以下のように動的なアクセスポイントを実装し、

```ruby
# app/models/auth_service.rb
class AuthService
  if Rails.env.production?
    def self.instance
      RealAuthService
    end
  else
    def self.instance
      MockedAuthService
    end
  end
end
```

さらにアプリケーションで`AuthService.instance`を代りに使用するという方法があります。`AuthService`は必要に応じて読み込まれ、自動読み込みとよく調和します。

### `require_dependency`とイニシャライザ

前述のとおり、`require_dependency`は自動読み込みと調和するようにファイルを読み込みます。しかし、このような呼び出しはイニシャライザ内では意味がないのが普通です。

イニシャライザ内で[`require_dependency`](#require-dependency)呼び出しを使用することで、たとえば[自動読み込みとSTI](#%E8%87%AA%E5%8B%95%E8%AA%AD%E3%81%BF%E8%BE%BC%E3%81%BF%E3%81%A8sti)の問題を修正しようとしたときと同様に特定の定数を確実に事前読み込みできます。

この方法の問題は、developmentモードでは、関連する変更がファイルシステム上で生じていなかった場合に[自動読み込みされた定数が完全にクリーンアップされてしまう](#定数の再読み込み)という点です。イニシャライザでのこのような定数の完全削除はぜひとも避けたいところです。

自動読み込みが行われる箇所で`require_dependency`を使用する場合は、十分戦略を練っておく必要があります。

### 定数がトリガーされない場合

#### 相対参照

フライトシミュレータについて考察してみましょう。このアプリケーションには以下のデフォルトのフライトモデルが1つあります。

```ruby
# app/models/flight_model.rb
class FlightModel
end
```

これは、以下のようにそれぞれの飛行機で上書きすることができます。

```ruby
# app/models/bell_x1/flight_model.rb
module BellX1
  class FlightModel < FlightModel
  end
end

# app/models/bell_x1/aircraft.rb
module BellX1
  class Aircraft
    def initialize
      @flight_model = FlightModel.new
    end
  end
end
```

イニシャライザは`BellX1::FlightModel`をひとつ作成しようとし、ネストには`BellX1`があります。一見したところ問題はなさそうにみえます。しかしここで、デフォルトのフライトモデルが読み込まれ、Bell-X1のフライトモデルが読み込まれていなかったとします。このとき、Rubyインタプリタはトップレベルの`FlightModel`を解決できるので、`BellX1::FlightModel`の自動読み込みはトリガーされません。

このコードの振る舞いは、実行パスの内容に依存します。

この種のあいまいさの解決には、以下のような修飾済み定数が役に立つことがしばしばあります。

```ruby
module BellX1
  class Plane
    def flight_model
      @flight_model ||= BellX1::FlightModel.new
    end
  end
end
```

以下のように`require_dependency`を使用して解決することもできます。

```ruby
require_dependency 'bell_x1/flight_model'

module BellX1
  class Plane
    def flight_model
      @flight_model ||= FlightModel.new
    end
  end
end
```

#### 修飾済み参照

以下の例について考察します。

```ruby
# app/models/hotel.rb
class Hotel
end

# app/models/image.rb
class Image
end

# app/models/hotel/image.rb
class Hotel
  class Image < Image
  end
end
```

`Hotel::Image`は実行パスに依存するので、この記法にはあいまいさが生じます。

[前述](#修飾済み定数を解決するアルゴリズム)のとおり、Rubyは`Hotel`とその先祖の定数を探索します。`app/models/image.rb`が読み込まれているが`app/models/hotel/image.rb`が読み込まれていない状況になった場合、Rubyは`Image`を`Hotel`内ではなく`Object`内で探索します。

```
$ bin/rails r 'Image; p Hotel::Image' 2>/dev/null
Image # これはHotel::Imageではない
```

`Hotel::Image`を評価するコードは、(おそらく`require_dependency`を使用して) `app/models/hotel/image.rb`を事前に読み込み済みの状態にしておく必要があります。

ただしこの方法を使用する場合、Rubyインタプリタは以下のような警告を出力します。

```
warning: toplevel constant Image referenced by Hotel::Image
```

この驚くべき定数解決方法は、実はどのクラスを修飾するときにも観察できます。

```
2.1.5 :001 > String::Array
(irb):1: warning: toplevel constant Array referenced by String::Array
=> Array
```

WARNING: この落とし穴を実際に観察するのであれば、名前空間の修飾はクラスである必要があります。`Object`はモジュールの先祖ではないからです。

### 特異クラス内で自動読み込みを行う

以下のクラス定義があるとしましょう。

```ruby
# app/models/hotel/services.rb
module Hotel
  class Services
  end
end

# app/models/hotel/geo_location.rb
module Hotel
  class GeoLocation
    class << self
      Services
    end
  end
end
```

`app/models/hotel/geo_location.rb`が読み込まれているときより前に`Hotel::Services`が認識されていれば、`Services`はRubyによって解決されます。これは、`Hotel::GeoLocation`の特異クラスがオープンされていると`Hotel`がネストに属するからです。

しかし`Hotel::Services`がその時点で認識されていなければ、Railsは`Hotel::Services`を自動読み込みできず、`NameError`が発生します。

その理由は、自動読み込みは特異クラスのためにトリガーされるからです。特異クラスは無名であり、Railsは[前述](#一般的な手順)のような極端な状況においてはトップレベルの名前空間しかチェックしません。

この警告を解決する簡単な方法のひとつに、定数を修飾するという方法があります。

```ruby
module Hotel
  class GeoLocation
    class << self
      Hotel::Services
    end
  end
end
```

### `BasicObject`の中で自動読み込みする

`BasicObject`の直系の子孫については、その先祖に`Object`がないためトップレベルの定数を解決できません。

```ruby
class C < BasicObject
  String # NameError: uninitialized constant C::String
end
```

ここに自動読み込みが絡んでくると事態が複雑になります。以下について考察してみましょう。

```ruby
class C < BasicObject
  def user
    User # 誤り
  end
end
```

Railsはトップレベルの名前空間をチェックするので、自動読み込みされた`User`は`user`メソッドが「最初に」呼び出されるときには問題なく動作します。その時点で`User`定数が既知の場合、特に`user`を*2度目に*呼び出した場合は例外が発生します。

```ruby
c = C.new
c.user # 驚くべきことにUserで問題が生じない
c.user # NameError: uninitialized constant C::User
```

これは、親の名前空間に既に定数が存在していることが検出されたためです。([修飾済み参照](#%E8%87%AA%E5%8B%95%E8%AA%AD%E3%81%BF%E8%BE%BC%E3%81%BF%E3%81%AE%E3%82%A2%E3%83%AB%E3%82%B4%E3%83%AA%E3%82%BA%E3%83%A0-%E4%BF%AE%E9%A3%BE%E6%B8%88%E3%81%BF%E5%8F%82%E7%85%A7)を参照)

純粋なRubyの場合と同様、`BasicObject`の直系の子孫オブジェクトの中では常に絶対定数パスを使用してください。

```ruby
class C < BasicObject
  ::String # 正しい

  def user
    ::User # 正しい
  end
end
```