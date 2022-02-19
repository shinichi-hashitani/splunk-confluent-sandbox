#  Splunkで収集されるネットワーク機器 (Cisco ASA) のログデータをConfluentで加工する実験環境 (Sandbox)

## Overview
ネットワーク機器のログをSplunkのUniversal Forwarderを利用してConfluentに転送し、ストリーム処理後にSplunkのHECに転送するサンドボックス環境。オリジナルはJohnny MirzaのSplunk Demoであり利用しているほぼ全てのリソースは彼の準備したもの。 (https://github.com/JohnnyMirza/confluent_splunk_demo) 本リポジトリはその内容を絞り、日本語化したもの。

### 備考
- 必要なConnectorは起動時に取得/設定される。しかしEnd-to-Endで繋がってはいない為中間処理は追加する必要がある。処理はksqlDBで記載する事を想定しているが必要条件ではない。
- ネットワーク機器からのログはGeneratorを使い生成したもの。同じレコードセットが繰り返しGeneratorから送られる。
- Splunkもコンテナ稼働しておりSink Connectorも定義済み。
- おまけとしてElasticならびにKibanaも定義されており起動している。但しConnectorは未定義。Connectorは読み込まれておりksqlDBにて登録/接続は可能。 (後述)
- 機器からのログはCISCO ASAのログだが他のログに切り替えも可能。（e.g. Nginx) ログ内容のカスタマイズも可能。

## 手順
このリポジトリをclone後、Docker Composeを起動。

```bash
git clone https://github.com/shinichi-hashitani/splunk-confluent-sandbox.git
cd splunk-confluent-sandbox
docker-compose up -d
```

### AWS EC2の事前準備
本Sandboxはローカル (Mac OS) 環境で作成/確認している。AWS EC2上で稼働する為の手順は以下の通り。
1. EC2インスタンスの生成。
    - AWS Linux2を想定。他でも動くが手順がやや異なる可能性あり。
    - t2.xlarge (4 core/16G) で確認。リソースにはだいぶ余裕あり。
    - Diskは50G程度割り当て。 (連続起動時間によってはもっと少なくても可)
2. Inbound Rulesに TCP/9021 (Confluent Control Center) 及びTCP/8000 (Splunk) を追加。
    - Elastic/Kibanaを利用する際には TCP/3000 (Kibana) をさらに追加。
3. sshでアクセス (cloud-shellでは作業不可)
4. Dockerのインストール
    ```bash
    sudo yum update -y
    yum install curl git
    # Amazon Linux2 以外ではさらに以下を実行
    # sudo yum install amazon-linux-extras
    sudo amazon-linux-extras install docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    # 確認
    docker info
    # Docker Composeの取得。不格好だがバイナリをそのまま取得
    sudo curl -L https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    sudo chmod 755 /usr/local/bin/docker-compose
    ```