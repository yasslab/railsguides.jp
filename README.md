[![Build Status](https://github.com/yasslab/railsguides.jp/actions/workflows/test.yml/badge.svg)](https://github.com/yasslab/railsguides.jp/actions)

[![Ruby on Rails ガイド - 体系的に Rails を学ぼう](https://raw.githubusercontent.com/yasslab/railsguides.jp/master/guides/assets/images/header-railsguides.png)](https://railsguides.jp/)

## 『Railsガイド』とは？

『Railsガイド』は [Ruby on Rails Guides](https://guides.rubyonrails.org/) に基づいた大型リファレンスガイドです。   
Railsの各機能を体系的に学び、プロダクト開発の生産性を高めたいときに役立ちます。

Ruby on Rails ガイド   
https://railsguides.jp/

これから Rails を勉強する方は『Railsチュートリアル』がオススメです。   

Ruby on Rails チュートリアル：実例を使ってRailsを学ぼう   
https://railstutorial.jp/

<br>

## フィードバックについて

Railsガイドを読んで誤字・脱字・誤訳などを見かけましたら、下記の『[ブラウザでRailsガイドの修正を提案する](https://github.com/yasslab/railsguides.jp#%E3%83%96%E3%83%A9%E3%82%A6%E3%82%B6%E3%81%A7rails%E3%82%AC%E3%82%A4%E3%83%89%E3%81%AE%E4%BF%AE%E6%AD%A3%E3%82%92%E6%8F%90%E6%A1%88%E3%81%99%E3%82%8B-%E3%82%AA%E3%82%B9%E3%82%B9%E3%83%A1)』に沿って [Pull Request](https://docs.github.com/ja/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests) (プルリク) を送っていただけると嬉しいです 😌

もし原著 (英語版) の間違いを見つけたら **プルリクチャンス** です! Railsガイドの『[Railsのドキュメントに貢献する](https://railsguides.jp/contributing_to_ruby_on_rails.html#rails%E3%81%AE%E3%83%89%E3%82%AD%E3%83%A5%E3%83%A1%E3%83%B3%E3%83%88%E3%81%AB%E8%B2%A2%E7%8C%AE%E3%81%99%E3%82%8B)』を参考に [:octocat: rails/rails](https://github.com/rails/rails) にプルリクを送ってみましょう 🌐🤝

『[Railsガイド](https://railsguides.jp/)』および『[Rails Guides](https://guides.rubyonrails.org/)』の品質向上に向けて、皆さまのご協力が得られれば嬉しいです 🙏✨

<br>

### ブラウザでRailsガイドの修正を提案する (オススメ)

多分これが一番簡単だと思います...!! 😆

1. ブラウザ上で [guides/source/ja](https://github.com/yasslab/railsguides.jp/tree/master/guides/source/ja) を開く
2. 直したいファイルを開く (例: [upgrading_ruby_on_rails.md](https://github.com/yasslab/railsguides.jp/blob/master/guides/source/ja/upgrading_ruby_on_rails.md))
3. 画面右にある ✎ アイコン (Fork this project and edit this file) をクリックする
4. 気になる箇所を修正し、修正内容にタイトルと説明文を付け、Propose file change をクリックする
5. 修正内容を確認し、問題なければ Create pull request をクリックする

以上で完了です。提案されたRailsガイドの修正はコミッターによって再確認され、問題なければ提案された内容が反映されます。もし問題があってもコミッター側で修正できるので、まずは気軽に提案してみてください :wink:

- 参考スライド: [⛩ OSS入門としてのRailsガイド 📕](https://speakerdeck.com/yasslab/railsguides-as-an-oss-gate)
- [&raquo; Railsガイド (日本語) への修正提案が、Rails Guides (英語) にも反映された例](https://github.com/rails/rails/pull/50756)
- [&raquo; これまでの修正提案（プルリクエスト）の一覧を見る](https://github.com/yasslab/railsguides.jp/pulls?q=is%3Apr+is%3Aclosed)

<br>

## Railsガイドの生成方法

Pull Request を送る前に生成結果を確認したい場合は下記をご参照ください。   
(生成結果を確認せずに Pull Request を送って頂いても大丈夫です! 😆👌)

### 1. 既存のHTMLファイルをローカルで生成および確認(Jekyll)

1. `$ bundle install`
2. `$ bundle exec rake assets:precompile`
3. `$ bundle exec jekyll server`
4. localhost:4000 から既存のHTMLファイルを確認する

### 2. 編集したHTMLをローカルで生成および確認 (Jekyll)

1. `/guides/source/ja` 内の Markdown ファイルを編集する
2. `$ bundle exec rake assets:precompile` 
3. `$ bundle exec jekyll server`
4. localhost:4000 から変更結果を確認する
5. (問題なければ) PR を送付する

### 3. Pull Request (PR) と Continuous Integration (CI)

- PR が送られると、[railsguides.jp の GitHub Actions](https://github.com/yasslab/railsguides.jp/actions) が走ります。
- CI が通らなかった場合は、該当箇所を修正してください。（`bundle exec rake test`でローカル環境でも確認できます）
- マージされない限り本番環境には反映されないので、PR は気軽に送ってください! 😆👌

## Podmanを利用したRailsガイドの生成方法

Podmanを利用して、簡単にローカルでRailsガイドの編集内容を確認することも可能です。
必要になるのはシェルスクリプトを実行できる環境とPodmanのみです。
Podmanのインストールに関しては[Podmanの公式インストールガイド](https://podman.io/docs/installation)をご覧ください。

Podmanがインストールできていれば、以下の手順でRailsガイドの編集と確認が行えます。

1. `/guides/source/ja` 内の Markdown ファイルを編集する
2. `$ bin/pmconfirm`
3. localhost:4000 から変更結果を確認する

なお、`$ bin/pmconfirm`は`vendor/bundle/`にgemをインストールしますので、
動作不良の際など、gemを一度全て削除したい場合は`rm -rf vendor/bundle/`で削除して下さい。

<!--
## 翻訳方法の変遷

以下はこれまでの翻訳フロー改善の流れを過去ログとしてまとめています。   
基本的に読む必要はありませんが、もし興味あれば適宜ご参照ください ;)

<details>
  <summary><strong>継続的翻訳システムについて (現在移行中)</strong></summary>

[![Railsガイドを支える継続的翻訳システム - SpeakerDeck](https://raw.githubusercontent.com/yasslab/railsguides.jp/master/yasslab/continuous_translation_system.png)](https://speakerdeck.com/yasulab/continuous-translation-system-at-rwc2015)

本リポジトリの仕組みについては、上記のスライドで詳しく解説されています。    
</details>


<details>
  <summary><strong>翻訳の流れ (継続的翻訳システム移行前の構成)</strong></summary>

![翻訳の流れ_v0](https://raw.githubusercontent.com/yasslab/railsguides.jp/master/yasslab/flow-of-translation_v0.png)
参考: [[翻訳]Ruby on Rails 4.1リリース前にアップグレードガイドを先行翻訳した & 同じ翻訳を2回しないで済むようにした](http://techracho.bpsinc.jp/hachi8833/2014_03_28/16037)

なお、移行後は次のようなフローで更新していく予定です。
![翻訳の流れ_v1](https://raw.githubusercontent.com/yasslab/railsguides.jp/master/yasslab/flow-of-translation_v1.png)
</details>

<details>
  <summary><strong>原著との差分を更新する方法</strong></summary>

- [bin/merge-upstream](https://github.com/yasslab/railsguides.jp/blob/master/railsguides.jp/bin/merge-upstrepam) を実行すると最新版が `guides/source` 内に取り込まれます。
- 特に、原著を手元で確認したいとき、原著にPRを送付したいときに便利です。
- 原著にPRを送るときは、事前に[Railsのドキュメントに貢献する](https://railsguides.jp/contributing_to_ruby_on_rails.html#rails%E3%81%AE%E3%83%89%E3%82%AD%E3%83%A5%E3%83%A1%E3%83%B3%E3%83%88%E3%81%AB%E8%B2%A2%E7%8C%AE%E3%81%99%E3%82%8B)に目を通しておくとよいです :)

</details>

<details>
  <summary><strong>GTTに最新のドキュメントをアップロードする</strong></summary>

- Google Translator Toolkit: https://translate.google.com/toolkit/
- Markdownは対応してないので、必要に応じてファイル名を `hogehoge.md.txt` などに変更する。
- **NOTE: 必ずRailsガイド用の翻訳メモリに結びつけること。(shared TM は使わない)**
   - cf. [翻訳メモリの使用 - Translate ヘルプ - Google Help](https://support.google.com/translate/toolkit/answer/147863?hl=ja)

</details>

<details>
<summary><b>GTT上で英語から日本語に翻訳する</b></summary>

- 詳細: [Google Translator Toolkitと翻訳メモリ(ノーカット版) : RubyWorld Conference 2013より](http://techracho.bpsinc.jp/hachi8833/2013_12_16/14889)
- GTTの使用方法や文体などに関しては[こちら](https://www.facebook.com/notes/ruby-on-rails-tutorial-%E7%BF%BB%E8%A8%B3%E3%82%B0%E3%83%AB%E3%83%BC%E3%83%97/google-translator-toolkit-gtt-%E3%81%AE%E4%BD%BF%E3%81%84%E6%96%B9/170100333166820)を参考にしてください。
- NOTE: 行頭にある`(TIP|IMPORTANT|CAUTION|WARNING|NOTE|INFO|TODO)[.:]`は、`guides:generate:html` で使われるタグです。 **これらのタグは訳さないでください。**

</details>
-->

<br>

## 運営チーム

本リポジトリは『創る』『学ぶ』を支援する [YassLab 株式会社](https://yasslab.jp/ja/) によって制作・運用されております。

📣 【PR】YassLab 社では[Railsガイド協賛プラン](https://railsguides.jp/sponsors)や、[Railsチュートリアル研修支援](https://railstutorial.jp/business)などにも対応しています。まずは無料の導入相談からぜひ! :pray: :sparkling_heart: 

<div>
  <a href="https://yasslab.jp/ja/#for-team">
    <img width="100%" src="/guides/assets/images/yasslab_pr_v2.png"
         alt="Services for Teams by YassLab Inc." />
  </a>
  <p>詳細：<a href="https://yasslab.jp/ja/#for-team">チーム向けサービス - YassLab 株式会社</a></p>
</div>

<br>

YassLab 社以外にも、次の方々が協力してくれました! 🤝✨    
様々なご意見・フィードバックありがとうございます! (＞人＜ )✨

### 協力者

- 👥 共同発起人 
  - [@hachi8833](https://github.com/hachi8833)
  - [@yasulab](https://github.com/yasulab)
- 💎 コミッターの皆さん
  - [@yui-knk](https://github.com/yui-knk)
  - [@riseshia](https://github.com/riseshia)
  - [@willnet](https://github.com/willnet)
- 👏 他、[Issues](https://github.com/yasslab/railsguides.jp/issues) や [Pull Request](https://github.com/yasslab/railsguides.jp/graphs/contributors) を送ってくださった多くの方々。

### 支援・協賛
Railsガイドでは、ドキュメントを通してRuby/Railsコミュニティを一緒に支援してくださる企業を募集しております。詳細は「<a href='https://railsguides.jp/sponsors'>協賛プラン</a>」のページよりご確認ください。

協賛プラン: [https://railsguides.jp/sponsors](https://railsguides.jp/sponsors)

[![協賛プラン バナー画像](/guides/assets/images/logos/bnr-kyosan.gif)](https://railsguides.jp/sponsors)

<br>

## ライセンス

[![CC BY-SA International](https://raw.githubusercontent.com/yasslab/railsguides.jp/master/yasslab/CC-BY-SA.png)](https://creativecommons.org/licenses/by-sa/4.0/deed.ja)

Railsガイドの[コンテンツ部分](https://github.com/yasslab/railsguides.jp/tree/master/guides/source)は[クリエイティブ・コモンズ 表示-継承 4.0 国際](https://creativecommons.org/licenses/by-sa/4.0/deed.ja) (CC BY-SA 4.0) ライセンスに基づいて公開されています。

ただし『Rails』や『Ruby on Rails』という名称、ならびに Rails のロゴ画像は [David Heinemeier Hansson の登録商標](https://rubyonrails.org/trademarks/)であり、本ライセンスの[対象ではありません](https://creativecommons.org/licenses/by-sa/4.0/legalcode#s2b)。また、本サイトのロゴ画像などの一部は [YassLab 社の著作物](https://yasslab.jp/ja/news/japanese-railsguides-logo)です。

[Ruby on Rails のソースコード](https://github.com/rails/rails)は [MIT ライセンス](http://www.opensource.org/licenses/MIT)に基づいて公開されています。

### クレジット

- 原著: [https://edgeguides.rubyonrails.org/#footer](https://edgeguides.rubyonrails.org/#footer)
- 本書: [https://railsguides.jp/#contributors](https://railsguides.jp/#contributors)

[![YassLab Inc.](https://yasslab.jp/img/logos/800x200.png)](https://yasslab.jp/ja/)
