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


