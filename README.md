# mecab-api

gooラボの[ひらがな化API](https://labs.goo.ne.jp/api/2014/338/)のクローン

## 動作条件

rubyのmecabバインディングであるnattoを利用しているため、
APIが動作する環境上にmecabのインストールが必要です。

herokuにデプロイする場合は、buildpackによりmecabとmecab-ipadicがインストールされます。  
（herokuでのアプリ作成時にbuildpack-multiを利用するように指定してください）

## ローカルでの起動方法

bundlerとforemanが無い場合は導入

```
$ gem install bundler foreman
```

リポジトリのcloneと起動

```
$ git clone https://github.com/knjcode/mecab-api
$ bundle install --path vendor/bundle
$ foreman start
```

これで、`localhost:5000`にAPIサーバが起動します。

## APIの使い方

application/json形式のPOSTで「ひらがな化」したい文字列を含むjsonデータを送信

### エンドポイント

**サーバURL/hiragana**

ローカルでforemanで起動した場合は

**localhost:5000/hiragana**

herokuで動かす場合

アプリ名が mecab-api-hogehoge の場合であれば

**https://mecab-api-hogehoge.herokuapp.com/hiragana**

### リクエストパラメータ

|名前|説明|
|:---|:----------|
|request_id |リクエストを識別するID（任意）<br>省略した場合は"リクエスト受付時刻[タブ文字]連番"|
|sentence   |ひらがな化する文字列（必須）|
|output_type|出力種別（任意）<br>hiragana（ひらがな化）、katakana（カタカナ化）いずれかを指定<br>省略時はひらがな化|
|normalize  |文字列の正規化処理（任意）<br>trueで正規化処理を実施、true以外や省略時は何もしない|

正規化処理は、mecab-ipadic-NEologdの[正規化処理](https://github.com/neologd/mecab-ipadic-neologd/wiki/Regexp.ja)に基づく処理を行います。

### レスポンスパラメータ

|名前|説明|
|:---|:----------|
|request_id |リクエストを識別するID<br>リクエスト時と同一|
|converted  |変換後文字列|
|normalized |文字列の正規化処理の有無<br>正規化した場合はtrue、していない場合はfalse|

### mecabコマンドの辞書を指定する

mecabコマンドが使用する辞書を指定したい場合には環境変数 `MECAB_API_DICDIR` に辞書のパスを指定します。

#### mecab-ipadic-NEologdを指定する例

```bash
# mecabの辞書のパスを確認
$ mecab-config --dicdir
/usr/local/Cellar/mecab/0.996/lib/mecab/dic

# インストールされている辞書を確認
$ ls /usr/local/Cellar/mecab/0.996/lib/mecab/dic
ipadic               mecab-ipadic-neologd mecab-unidic-neologd unidic

# mecab-ipadic-NEologdを指定
$ export MECAB_API_DICDIR="/usr/local/Cellar/mecab/0.996/lib/mecab/dic/mecab-ipadic-neologd"
```

## 入出力サンプル

### 入力例

{“sentence”:”漢字が混ざっている文章”, “output_type”:”hiragana”}

### 出力例

{"request_id":"1433502140\t0","converted":"かんじ が まざっ て いる ぶんしょう","normalized":false}

## コマンドラインでのテスト方法

```bash
$ curl -H "Content-type: application/json" -X POST -d '{"sentence":"漢字が混ざっている文章","output_type":"hiragana"}' 'localhost:5000/hiragana'

{"request_id":"1433502140\t0","converted":"かんじ が まざっ て いる ぶんしょう","normalized":false}
```

## herokuにデプロイして使う場合

herokuにデプロイする場合はアプリ作成時にbuildpack-multiを利用するように指定してください。

[Heroku buildpack: linuxbrew](https://github.com/sunny4381/heroku-buildpack-linuxbrew.git)を利用して、mecabとmecab-ipadicをheroku環境にインストールします。

```bash
$ heroku apps:create [任意のアプリ名] --buildpack https://github.com/heroku/heroku-buildpack-multi
Creating [指定したアプリ名]... done, stack is cedar-14
Buildpack set. Next release on mecab-api-suraraka will use https://github.com/heroku/heroku-buildpack-multi.
https://mecab-api-suraraka.herokuapp.com/ | https://git.heroku.com/mecab-api-suraraka.git
Git remote heroku added
$ git push heroku master

# newrelicを利用する場合は以下も実行
$ heroku addons:create newrelic
```

heroku上のAPIサーバのAPIを使う例

```bash
$ curl -H "Content-type: application/json" -X POST -d '{"sentence":"すもももももももものうち","output_type":"hiragana"}' 'https://[herokuのアプリ名].herokuapp.com/hiragana'

{"request_id":"1433604355\t0","converted":"すもも も もも も もも の うち","normalized":false}
```
