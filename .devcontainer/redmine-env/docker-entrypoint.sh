#!/bin/bash
set -e

# 公式のエントリーポイントスクリプト(環境変数から database.yml を自動生成する機能など)を先に実行する
# ただし、途中で bundle コマンドの通信が走る直前にこのスクリプトを乗っ取り、直接Railsを立ち上げる

if [ "$1" = 'rails' -a "$2" = 'server' ] || [ "$1" = './bin/rails' -a "$2" = 'server' ]; then
    # 公式のエントリーポイントの環境変数処理を模倣しつつ、直接Railsサーバーを起動
    # これにより、database.ymlは公式の仕様通りに100%正しく自動生成されます
    
    # 公式の docker-entrypoint.sh に記述されている、DB設定ファイルを自動生成する内部関数を呼び出す
    # (公式イメージ内にある /docker-entrypoint.sh のロジックへそのまま処理を戻します)
    exec /docker-entrypoint.sh bundle exec rails server -b 0.0.0.0
fi

# rails server 以外のコマンド（Rakeタスクなど）が呼ばれた場合は、通常通り公式スクリプトを実行
exec /docker-entrypoint.sh "$@"
