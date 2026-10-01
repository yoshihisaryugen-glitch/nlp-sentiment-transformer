# NLP SENTIMENT TRANSFORMER
## 前提

- Docker Desktop が起動していること

コンテナ内は CPU 版 PyTorch です。Mac 上の Docker からは GPU を使いません。

ノートブックは `torchtext.data.Field` を使います。この API が残っている torch 1.7.1 のホイールは linux/amd64 だけです。Apple Silicon では `docker-compose.yml` の `platform: linux/amd64` によりエミュレーションで動きます。学習は CPU 上なので時間がかかります。

## 起動

```bash
docker compose up -d --build
```

起動後、ブラウザで次を開きます。トークンは不要です。

http://127.0.0.1:8887/lab

この環境はホストの 8887 番を使います。8888 番は第1章や、手元で起動している JupyterLab と重ならないようにしています。

初回起動時に、次のファイルを `data/` へダウンロードして解凍します。すでに存在する場合はスキップします。合計で 2GB を超えるため、初回は時間がかかります。

- `data/entity_vector/`（東北大学の日本語 Word2Vec、約 1.3GB）
- `data/wiki-news-300d-1M.vec`（英語 fastText、約 650MB）
- `data/aclImdb/`（IMDb のレビュー）

`data/vector_neologd.zip` は Google Drive からの手動ダウンロードです。ノートブック `make_folders_and_data_downloads.ipynb` にリンクがあります。zip を `data/` に置いてコンテナを再起動すると、`data/vector_neologd/` に解凍します。7-4 の日本語 fastText 以外では使いません。

## 止める

```bash
docker compose down
```

`docker compose down` ではノートブックと `data/` は消えません。イメージも残ります。

## 実行するノートブック

この環境では、同じディレクトリにある次のファイルを開きます。

| ノートブック | 内容 |
| --- | --- |
| `7-1_Tokenizer.ipynb` | Janome と MeCab+NEologd で分かち書きする |
| `7-2_torchtext.ipynb` | torchtext で Dataset と DataLoader を作る |
| `7-2-2_Dataset_DataLoader.ipynb` | 7-2 と同じ処理を、今の Dataset と DataLoader で書く |
| `7-4_vectorize.ipynb` | 日本語と英語の学習済み単語ベクトルを読み込む |
| `7-4-2_vectorize.ipynb` | 7-4 と同じ処理を、今の Dataset と辞書で書く |
| `7-5_IMDb_Dataset_DataLoader.ipynb` | IMDb から DataLoader を作る |
| `7-6_Transformer.ipynb` | Transformer の各層を確認する |
| `7-7_transformer_training_inference.ipynb` | 感情分析モデルを学習して推論する |

`make_folders_and_data_downloads.ipynb` のダウンロード処理は、`vector_neologd` 以外をコンテナ起動時に済ませています。

## パッケージ

ノートブックの `torchtext.data.Field` に合わせ、次のバージョンに固定しています。

- Python 3.9
- torch 1.7.1（CPU）
- torchtext 0.8.1
- gensim 3.8.3（`KeyedVectors` の `.wv` を使うため）

MeCab と NEologd はイメージに入っています。辞書のパスはノートブックと同じ `/usr/lib/mecab/dic/mecab-ipadic-neologd` です。

一覧は `requirements.txt` を見てください。

## 構成

```text
Dockerfile              Python 3.9、MeCab+NEologd、依存パッケージ
docker-compose.yml      JupyterLab をホストの 8887 番で公開する
docker/entrypoint.sh    データ取得のあと JupyterLab を起動する
requirements.txt        固定したパッケージ
```

カレントディレクトリはコンテナの `/workspace` にマウントされます。ノートブックの保存や `data/` への追記は、ホスト側のこのディレクトリに残ります。
