# B->Dash Shampoohat Library

このgemは、SOAPベースのAPIのためのクライアントライブラリです。
`shampoohat`をベースにしています。
現在、以下のAPIに対応していることを確認しています。
- Yahoo! Ads API
- Criteo API

# 背景
- B->Dashは、既にGoogle Adwords APIの連携済みです。
- その連携に、`shampoohat`と`google-adwords-api`の2つのgemを利用しています。
- `shampoohat`は、汎用的なSOAPクライアントである`savon`というgemを利用していますが、このバージョンが1系と古いままです。
  - このアップグレード問題は既に報告されていますが、対応はなかなか難しいようです。

  [Upgrade Savon (Savon 1 is deprecated) · Issue #15 · googleads/google-api-ads-ruby](https://github.com/googleads/google-api-ads-ruby/issues/15)

- 他のSOAPベースのAPIとの連携を考えた場合、`savon`の利用は必須で、`ads-common`が1系である以上、このバージョンが1系に縛られてしまいます。
- この問題への対応方法は、以下の2つに絞られますが、2の方がメリットが大きいため、こちらを考えます。
  - 1.`ads-common`をForkして、2系にアップグレードした上で、2系で他のAPIクライアントを作成する
  - 2.他のAPIも1系のまま開発する
- SOAPでは、WSDLというインタフェースが定義されており、公開されています。つまり、このWSDLがあれば、APIクライアントを自動的に構築することができます。
  - 実際、`ads-common`は、AdwordsのWSDLから、`google-adwords-api`を自動生成するためのライブラリです。(`rake generate`コマンドを実行すると、adwords-apiのlibを自動生成してくれます。)
  - そこで、`ads-common`を改良して、Yahoo! Adsや、CRITEOに対応した、汎用的なSOAPベースのAPIを自動生成するライブラリを作成します。
  - これが、`shampoohat` gemになります。

# Docs for Users

## 1 - Installation:

`shampoohat` is a Ruby gem.
Install it using the gem install command.

    $ gem install shampoohat, github: "f-scratch/shampoohat"

The following gem libraries are required:

 - savon
 - httpi
 - signet

# Docs for Developers

## 1 - Directory Structure

- `lib/shampoohat/`: Contains the bulk of the library.
  - `auth/`: Contains classes that can handle different authentication methods.
    Currently only supports ClientLogin.
  - `build/`: Contains classes that handle code generation, packaging and other
    build-time tasks for client libraries (not for shampoohat).
  - `savon_headers/`: Contains classes that handle header injection into savon
    requests.
- `test/`: Contains the unit tests for the library.


## 2 - Commands

To build the gem:

    $ gem build shampoohat.gemspec

To run unit tests on the library:

    $ rake test

## Authors

 - Junya Wako(junwako@gmail.com)
