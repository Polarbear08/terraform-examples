# 02_SpotFleet_Request
スポットフリートリクエストを利用してスポットインスタンスを起動する。

## 前提
01と同じ

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
