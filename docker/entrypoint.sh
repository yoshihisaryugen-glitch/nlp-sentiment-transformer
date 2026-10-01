#!/bin/bash
set -euo pipefail

python - <<'PY'
import os
import tarfile
import urllib.request
import zipfile

data_dir = "/workspace/data"
os.makedirs(data_dir, exist_ok=True)


def download(url, dest):
    print("Downloading", url, flush=True)

    def reporthook(block, block_size, total):
        if total <= 0 or block % 2000 != 0:
            return
        done = min(block * block_size, total)
        print(f"  {done // (1024 * 1024)} / {total // (1024 * 1024)} MB", flush=True)

    urllib.request.urlretrieve(url, dest, reporthook)


def extract_tar(archive_path, dest_dir):
    print("Extracting", archive_path, flush=True)
    with tarfile.open(archive_path) as archive:
        archive.extractall(dest_dir)


def extract_zip(archive_path, dest_dir):
    print("Extracting", archive_path, flush=True)
    with zipfile.ZipFile(archive_path) as archive:
        archive.extractall(dest_dir)


entity_bin = os.path.join(data_dir, "entity_vector", "entity_vector.model.bin")
if not os.path.exists(entity_bin):
    archive = os.path.join(data_dir, "20170201.tar.bz2")
    if not os.path.exists(archive):
        download(
            "https://www.cl.ecei.tohoku.ac.jp/~m-suzuki/jawiki_vector/data/20170201.tar.bz2",
            archive,
        )
    extract_tar(archive, data_dir)

fasttext_vec = os.path.join(data_dir, "wiki-news-300d-1M.vec")
if not os.path.exists(fasttext_vec):
    archive = os.path.join(data_dir, "wiki-news-300d-1M.vec.zip")
    if not os.path.exists(archive):
        download(
            "https://dl.fbaipublicfiles.com/fasttext/vectors-english/wiki-news-300d-1M.vec.zip",
            archive,
        )
    extract_zip(archive, data_dir)

imdb_dir = os.path.join(data_dir, "aclImdb")
if not os.path.isdir(imdb_dir):
    archive = os.path.join(data_dir, "aclImdb_v1.tar.gz")
    if not os.path.exists(archive):
        download(
            "https://ai.stanford.edu/~amaas/data/sentiment/aclImdb_v1.tar.gz",
            archive,
        )
    extract_tar(archive, data_dir)

neologd_vec = os.path.join(data_dir, "vector_neologd")
neologd_zip = os.path.join(data_dir, "vector_neologd.zip")
if os.path.isfile(neologd_zip) and not os.path.isdir(neologd_vec):
    os.makedirs(neologd_vec, exist_ok=True)
    extract_zip(neologd_zip, neologd_vec)
elif not os.path.isdir(neologd_vec):
    print(
        "vector_neologd は Google Drive からの手動配置です。"
        " 7-4 の日本語 fastText を使うときだけ data/vector_neologd.zip を置いてください。",
        flush=True,
    )
PY

python - <<'PY'
import importlib.util
import subprocess
import sys

if importlib.util.find_spec("ipywidgets") is None:
    subprocess.check_call([
        sys.executable, "-m", "pip", "install", "--no-cache-dir", "ipywidgets==8.1.3",
    ])
PY

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# CLI の空トークンは jupyter-server 2.18 だと無視され、ログイン画面が残る。
# 設定ファイルで ServerApp と IdentityProvider の両方を空にする。
cat > /tmp/jupyter_server_config.py <<'EOF'
c.ServerApp.token = ""
c.ServerApp.password = ""
c.ServerApp.allow_remote_access = True
c.IdentityProvider.token = ""
c.PasswordIdentityProvider.token = ""
c.PasswordIdentityProvider.hashed_password = ""
EOF

exec jupyter lab \
  --config=/tmp/jupyter_server_config.py \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --allow-root \
  --ServerApp.allow_origin="*" \
  --ServerApp.root_dir=/workspace \
  --LabApp.extension_manager=readonly
