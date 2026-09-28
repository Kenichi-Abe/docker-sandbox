# Redmine 4.1.1 + Percona 5.7 (GitHub Codespaces)

plugins と vendor を **ビルド時にイメージへ内包** する構成です。

## ディレクトリ

```
.
├── Dockerfile                 # Redmine 4.1.1（推奨: 公式 redmine:4.1.1 ベース）
├── Dockerfile.from-source     # 公式タグが pull できないときの代替
├── docker-compose.yml
├── .devcontainer/devcontainer.json
├── plugins/                   # ここにプラグインを置く → イメージに焼かれる
├── vendor/                    # vendor/bundle など → イメージに焼かれる
├── themes/                    # 追加テーマ（任意）
└── percona/
    ├── Dockerfile
    └── conf.d/redmine.cnf
```

## 事前準備

1. `plugins/` にプラグインを配置する（ディレクトリ名がプラグイン名）。
2. オフライン用に gem を固める場合は、あらかじめ `vendor/bundle` を作って置く。
3. 環境変数は `.env.example` をコピーする。

```bash
cp .env.example .env
```

## ビルドと起動

```bash
docker compose build
docker compose up -d
```

ブラウザ: http://localhost:3000  
初期アカウント: `admin` / `admin`

## GitHub Codespaces

1. このディレクトリをリポジトリのルート（または Codespaces で開くフォルダ）にする。
2. Codespaces で開くと `.devcontainer/devcontainer.json` が `docker-compose.yml` を使う。
3. プラグインを足したら **イメージの再ビルド** が必要。

```bash
docker compose build redmine --no-cache
docker compose up -d redmine
```

## 重要な注意

- `plugins` / `vendor` を compose の volumes で上書きしないこと。マウントするとイメージに焼いた内容が隠れる。
- 公式 `redmine:4.1.1` が pull できない場合は `docker-compose.yml` の Redmine 側を次のように変える。

```yaml
    build:
      context: .
      dockerfile: Dockerfile.from-source
```

- Redmine 4.1.1 / Percona 5.7 / Ruby 2.6 はいずれも EOL。検証・移行用途向け。
- Codespaces や公開リポジトリでは `.env` のパスワードを必ず変える。

## よく使うコマンド

```bash
# プラグイン migrate だけ再実行
docker compose exec redmine bundle exec rake redmine:plugins:migrate RAILS_ENV=production

# DB クライアント
docker compose exec db mysql -uredmine -predminepass redmine
```
