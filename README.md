# mNi Cloud installation

このリポジトリは、mNi Cloud `0.2.x`系列の構成を管理します。

## 必須コンポーネント

| コンポーネント | バージョン | 用途 |
| --- | --- | --- |
| Juneau | `v1.0.0-rc.9` | VPC、Container、VM、VPNが利用するCNI・VPCデータプレーン |
| KubeVirt | `v1.8.4` | VMの実行基盤 |
| CDI | `v1.65.0` | VMイメージの取り込みとディスク複製 |
| CSI snapshot-controller | `v8.5.0` | `VolumeSnapshot` CRDとスナップショット制御 |
| Kodiak | `v0.2.5` | VPNが利用するConnector Operator。KodiakのHelm chartでIonscaleも構成する |
| cert-manager | `v1.21.1` | mNi controllerのWebhook証明書管理 |
| dependency-controller | `0.1.12` | mNiリソース間の依存関係管理 |
| Anchorage | `0.2.x` | auth-controllerとAPI Gatewayが利用する認証・認可基盤 |

Juneau、KubeVirt、CDI、snapshot-controller、Kodiak、cert-manager、
dependency-controllerおよびAnchorageは、mNiの機能を成立させる必須コンポーネントです。

CSIドライバーとStorageClass、JuneauのExternalNetwork・AddressPool・BGPPeer、
外部公開用のDNS・Tunnel・リバースプロキシはクラスタ固有の設定であり、
installationでは特定の実装や値を固定しません。
