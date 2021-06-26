# 01_Single_EC2
EC2インスタンスを作成する。

## 前提
`.aws` ディレクトリ以下に `credentials`ファイルを作成し、`credentials`ファイルを作成する。

```
[terraform-tutorial]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

インスタンスにアクセスするためのキーペアを作成する。
パスフレーズは不要。`~/.ssh/id_XXXX`のようなパスに作成する。

```
$ ssh-keygen -t rsa -b 4096
```

`main.tf`と同一階層に`terraform.tfvars`を作成し、以下のように値を設定する。
`public_key`には`cat ~/.ssh/id_XXXX.pub` した結果を記載する。

```
local_ips  = ["XXX.XXX.XXX.XXX/32"]
public_key = "ssh-rsa AAAA....."
```

## 実行

```
$ terraform plan
```

エラーが出なければ以下を実行する。

```
$ terraform apply
```

しばらくすると "Do you want to perform these actions?" というプロンプトが出るので、"yes"と入力する。

正常に終了すると、起動したインスタンスのIPアドレスが表示される。

```
instance_ip = "3.90.250.149"
```

sshでログインを試みる。

```
$ ssh -i ~/.ssh/id_XXXX centos@<instance_ip>
```

ログインできれば成功
