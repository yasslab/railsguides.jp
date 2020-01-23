[![Build Status](https://travis-ci.org/yasslab/railsguides.jp.svg?branch=master)](https://travis-ci.org/yasslab/railsguides.jp)

[![Banner of Railsガイド](https://yasslab.jp/img/header-railsguides.png)](https://railsguides.jp/)

## 『Railsガイド』とは？

『Railsガイド』は [Ruby on Rails Guides](http://guides.rubyonrails.org/) の[公式の日本語版](https://guides.rubyonrails.org/contributing_to_ruby_on_rails.html#translating-rails-guides)です。   
Rails の各機能の仕組みや最新の機能、リリース情報などがまとまっています。

Ruby on Rails ガイド   
https://railsguides.jp/

これから Rails を勉強する方は『Railsチュートリアル』がオススメです。   
Railsガイドと同様に、『Railsチュートリアル』もWeb版は無料で読めます :)

Ruby on Rails チュートリアル：実例を使ってRailsを学ぼう   
https://railstutorial.jp/


## フィードバックについて

Railsガイドを読んで、誤字・脱字・誤訳などを見かけましたら、本リポジトリの [Issue](https://github.com/yasslab/railsguides.jp/issues) にてお気軽に報告して頂けると幸いです。「Pull Request を送ってみたい!」という場合は、下記の『[Railsガイドの生成方法](https://github.com/yasslab/railsguides.jp#rails%E3%82%AC%E3%82%A4%E3%83%89%E3%81%AE%E7%94%9F%E6%88%90%E6%96%B9%E6%B3%95)』を参照してください。

もし原著の間違いを見つけましたら、Railsガイドの『[Railsのドキュメントに貢献する](https://railsguides.jp/contributing_to_ruby_on_rails.html#rails%E3%81%AE%E3%83%89%E3%82%AD%E3%83%A5%E3%83%A1%E3%83%B3%E3%83%88%E3%81%AB%E8%B2%A2%E7%8C%AE%E3%81%99%E3%82%8B)』を参考にしてください。

『[Railsガイド](https://railsguides.jp/)』および『[Rails Guides](https://guides.rubyonrails.org/)』の品質向上に向けて、皆さまのご協力が得られれば嬉しいです ;)

### ブラウザでRailsガイドの修正を提案する

多分これが一番簡単だと思います...!! 😆

1. ブラウザ上で [guides/source/ja](https://github.com/yasslab/railsguides.jp/tree/master/guides/source/ja) を開く
2. 直したいファイルを開く (例: [upgrading_ruby_on_rails.md](https://github.com/yasslab/railsguides.jp/blob/master/guides/source/ja/upgrading_ruby_on_rails.md))
3. 画面右にある ✎ アイコン (Fork this project and edit this file) をクリックする
4. 気になる箇所を修正し、修正内容にタイトルと説明文を付け、Propose file change をクリックする
5. 修正内容を確認し、問題なければ Create pull request をクリックする

以上で完了です。提案されたRailsガイドの修正はコミッターによって再確認され、問題なければ提案された内容が反映されます。もし問題があってもコミッター側で気付いて修正することができるので、まずはお気軽に提案してみてください ;)


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

- PR が送られると、[railsguides.jp の Travis CI](https://travis-ci.org/yasslab/railsguides.jp) が走ります。
- CI が通らなかった場合は、該当箇所を修正してください。
- マージされない限り本番環境には反映されないので、PR は気軽に送っていただければ ;)

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

## 運営チーム

本リポジトリは Ruby/Rails の開発を支援する [YassLab 株式会社](https://yasslab.jp/ja/) によって制作・運用されております。

📣 【PR】YassLab 社では開発支援も承っております。もし興味あればお気軽にご相談ください ;)

<div>
  <a href="https://yasslab.jp/ja/agile">
    <img width="60%" src="https://yasslab.jp/img/team.png"
         alt="YassLab Images" />
  </a>
  <a href="https://yasslab.jp/ja/agile">
    <img width="60%" src="https://yasslab.jp/img/skills.png"
         alt="YassLab Skills" />
  </a>
  <p>【PR END】詳細：<a href="https://yasslab.jp/ja/agile">Ruby/Rails の開発支援サービス - YassLab 株式会社</a></p>
</div>

　

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

### 相談部屋

[idobata.io](https://idobata.io) の [yasslab/railsguides-public](https://idobata.io/#/organization/yasslab/room/railsguides-public) 部屋にて、Rails ガイドに関する情報交換しています。   
覗いてみるだけの方も歓迎なので、是非お気軽に立ち寄ってみてください :D

<a href="https://idobata.io/#/organization/yasslab/room/railsguides-public">
  <img width="60%" alt="Idobata でのチャット例"
   src="https://raw.githubusercontent.com/yasslab/railsguides.jp/master/yasslab/idobata-screenshot.png"
  />
</a>


## ライセンス

[![CC BY-SA International](https://raw.githubusercontent.com/yasslab/railsguides.jp/master/yasslab/CC-BY-SA.png)](https://creativecommons.org/licenses/by-sa/4.0/deed.ja)

Railsガイドのコンテンツは[クリエイティブ・コモンズ 表示-継承 4.0 国際](https://creativecommons.org/licenses/by-sa/4.0/deed.ja) (CC BY-SA 4.0) ライセンスに基づいて公開されています。

「Rails」および「Ruby on Rails」という名称、そして Rails のロゴは、David Heinemeier Hansson による登録商標で、すべての権利を有しています。

[Ruby on Rails](http://rubyonrails.org/) は [MIT ライセンス](http://www.opensource.org/licenses/MIT)に基づいて公開されています。

### クレジット

- 原著: [https://edgeguides.rubyonrails.org/#footer](https://edgeguides.rubyonrails.org/#footer)
- 本書: [https://railsguides.jp/#contributors](https://railsguides.jp/#contributors)

[![YassLab Inc.](https://yasslab.jp/img/logos/800x200.png)](https://yasslab.jp/ja/)
