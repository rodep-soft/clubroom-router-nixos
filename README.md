# Dotfiles

部室でルータ用に置いているnixosの設定ファイル管理用repo.

`/etc/nixos/*`と一致しています.

ルータ設定は以下を流用しています.

[wifi_as_wan](https://github.com/lazytatzv/wifi_as_wan_with_nixos)

## ネットワーク設定

`iwd`と`systemd-networkd`を使用しています. `/var/lib/iwd`以下に設定ファイルを記述することで使用可能になります.

大学のwifiに接続する時は、[iwd](https://wiki.archlinux.org/title/Iwd)の`3.2.2`を参考にするか、[wifi_as_wan](https://github.com/lazytatzv/wifi_as_wan_with_nixos)の設定ファイルを参考にすると良いでしょう.

## NAS設定

`nfs`サーバを建てているのでLinuxユーザは簡単に利用することができます.

```bash
# nfs clientのインストール

## arch
sudo pacman -S nfs-utils

## debian
sudo apt install nfs-common

# Load module
sudo modprobe nfs

## check
lsmod | grep nfs

# Mount
# <IP ADDR>は実際のipアドレスに置き換えて下さい
# tailscaleのdomainname/addressで問題ありません
# マウントポイントも自由です(/mntじゃなくていい)
sudo mount -t nfs <IP_ADDR>:/data /mnt

# mount永続化
# /etc/fstabに記述
<IP_ADDR>:/data  /mnt/nfs  nfs  _netdev,nofail,x-systemd.automount  0  0

```

## ブラウザからDriveにアクセス(/data)

[filebrowser](http://router:8080/settings/profile)

## 広告ブロック (AdGuard Home)

LAN内のDNS問い合わせで広告・トラッカーを自動ブロックする `AdGuard Home` を稼働させています。

### 管理画面 (Web UI)
* **URL**: `http://192.168.50.1:3000` (または `http://<Tailscale_IP>:3000`)
* **機能**:
  * リアルタイムのクエリログ・ブロック状況の確認
  * 誤検知されたサイトのホワイトリスト（許可）登録
  * 広告ブロックフィルタの追加・管理

## Web ファイルマネージャー (FileBrowser)

NFSの共有フォルダ `/data` をブラウザから直接閲覧・アップロード・ダウンロードできる `FileBrowser` を稼働させています。

### アクセス方法
* **URL**: `http://192.168.50.1:8080` (または `http://<Tailscale_IP>:8080`)
* **初期ログイン情報**:
  * ユーザー名: `admin`
  * パスワード: `admin`
  * ※ 初回ログイン後、左側メニューの「Settings（設定）」からパスワード変更や部員用アカウントの追加が可能です。




## 部内 Web サービス一覧 (リバースプロキシ)

部室 LAN に接続しているデバイスのブラウザから、ポート番号不要でアクセス可能です：

* 🌐 **NAS / ファイルマネージャー**: [http://nas.lan](http://nas.lan) (または [http://drive.lan](http://drive.lan) / [http://router.lan](http://router.lan))
* 🛡️ **広告ブロック管理 (AdGuard Home)**: [http://adguard.lan](http://adguard.lan) (または [http://dns.lan](http://dns.lan))
* 📊 **ハードウェア & ネットワーク監視 (Grafana)**: [http://grafana.lan](http://grafana.lan) (または [http://monitor.lan](http://monitor.lan) / [http://status.lan](http://status.lan))
* ⚡ **分散コンパイル監視 (distcc Web)**: [http://distcc.lan](http://distcc.lan)

## ⚡ 分散コンパイル & リモートビルダーの利用ガイド

部員のノート PC（MacBook や Linux）のビルド処理を、部室ルーターの 8C/16T（i7-11800H）に肩代わりさせるための手順です。

---

### 1. `distcc` による通常ビルドの分散化（ROS 2 / C++ / CMake / Make）
> `flake.nix` の作成やプロジェクトファイルの変更は不要です。

#### ① クライアント PC に `distcc` をインストール
* **Ubuntu / Debian**: `sudo apt install distcc`
* **Arch Linux**: `sudo pacman -S distcc`
* **macOS**: `brew install distcc`

#### ② ターミナルで環境変数を設定（`~/.bashrc` や `~/.zshrc` に追記推奨）
```bash
# 部室 LAN 接続時（16スレッド並列指定）
export DISTCC_HOSTS="192.168.50.1/16"

# ※ Tailscale 経由で自宅からビルドする場合は Tailscale IP または nixos を指定:
# export DISTCC_HOSTS="<Tailscale-IP>/16"

# コンパイラを distcc 経由に切り替え
export CC="distcc gcc"
export CXX="distcc g++"
```

#### ③ いつも通りビルドを実行
```bash
# ROS 2 の場合 (16並列で爆速ビルド)
colcon build --parallel-workers 16

# 通常の CMake / Make の場合
make -j16
# または cmake --build build -j16
```
* 📊 **リアルタイム分散状況の確認**: ブラウザで [http://distcc.lan](http://distcc.lan)（または `http://<Tailscale-IP>:3633`）を開くと、リアルタイムで各コンパイルジョブの分散状況が見えます。

---

### 2. Nix リモートビルダー（Nix / Flakes / macOS Apple Silicon 対応）
> MacBook (M1/M2/M3) からでも Linux 用バイナリ・ROS 2・Docker コンテナをルーター上でビルド可能。

#### ① 部員の SSH 公開鍵をルーターに登録
ルーターの `/home/yano/.ssh/authorized_keys` に部員の公開鍵を追記。

#### ② 部員の PC の `~/.config/nix/nix.conf` に設定を追加
```conf
builders = ssh://yano@192.168.50.1 x86_64-linux - 16 1 kvm,benchmark,big-parallel
```
*(Tailscale 経由の場合は `ssh://yano@nixos` または `ssh://yano@<Tailscale-IP>`)*

#### ③ ビルドを実行
```bash
nix build
# または
nix develop
```
自動的にルーターへソースが送られ、ルーターの RAM ディスク上で並列ビルドされた完成品だけが手元に戻ってきます。

---

### 3. VS Code Remote SSH（GUI でコード編集 + ルーター側で実行）
1. VS Code 拡張機能「**Remote - SSH**」をインストール。
2. `ssh yano@192.168.50.1`（または Tailscale の `ssh yano@nixos`）に接続。
3. ルーター内のプロジェクトフォルダを開くことで、快適にコードを書きつつ、16スレッドの爆速ビルドと実行を行えます。

---

---

## Nix Flakes によるデプロイと運用

本リポジトリは **Nix Flakes** および **モジュール分割** に対応しています。

### ディレクトリ構成
```
.
├── flake.nix                  # Flake定義エントリーポイント
├── configuration.nix          # ホスト設定 (modules + hardware-configuration をインポート)
├── hardware-configuration.nix # ハードウェア自動生成設定
├── Makefile                   # 管理用ショートカットコマンド
└── modules/                   # 機能ごとの分割モジュール
    ├── default.nix            # モジュール一括インポート
    ├── performance.nix        # 高性能カーネル(Zen)、BBR+CAKE、tmpfs、sysctlチューニング
    ├── router.nix             # WiFi-as-WAN、AdGuard Home、Firewall設定
    ├── proxy.nix              # Caddy リバースプロキシ (*.lan ローカルドメイン)
    ├── monitoring.nix         # Prometheus + Node Exporter + Grafana 監視基盤
    ├── services.nix           # Tailscale、NFS、FileBrowser、Docker、SSH
    ├── runner.nix             # GitHub Actions Self-Hosted Runner (rodep-soft)
    ├── system.nix             # ユーザー(yano)、パッケージ、自動GC、最適化
    └── wifi-as-wan.nix        # WiFi as WAN モジュール定義
```

### 設定の反映 (Nix Flakes)
リポジトリ内で以下を実行するだけで適用できます：

```bash
# 設定をビルドして即時適用
make switch
# (または sudo nixos-rebuild switch --flake .#nixos)

# 再起動時にのみ反映させる場合
make boot

# Flake の依存関係（nixpkgs等）のアップデート
make update
```
