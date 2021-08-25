---
# try also 'default' to start simple
theme: seriph
# random image from a curated Unsplash collection by Anthony
# like them? see https://unsplash.com/collections/94734566/slidev
background: https://source.unsplash.com/collection/94734566/1920x1080
# apply any windi css classes to the current slide
class: 'text-center'
# https://sli.dev/custom/highlighters.html
highlighter: shiki
# show line numbers in code blocks
lineNumbers: false
# some information about the slides, markdown enabled
info: |
  ## Slidev Starter Template
  Presentation slides for developers.

  Learn more at [Sli.dev](https://sli.dev)
---

# Terraformで国を作る

インフラ管理ツール Terraform について

<div class="pt-12">
  <span @click="$slidev.nav.next" class="px-2 py-1 rounded cursor-pointer" hover="bg-white bg-opacity-10">
    Press Space for next page <carbon:arrow-right class="inline"/>
  </span>
</div>

<div class="abs-br m-6 flex gap-2">
  <button @click="$slidev.nav.openInEditor()" title="Open in Editor" class="text-xl icon-btn opacity-50 !border-none !hover:text-white">
    <carbon:edit />
  </button>
  <a href="https://github.com/slidevjs/slidev" target="_blank" alt="GitHub"
    class="text-xl icon-btn opacity-50 !border-none !hover:text-white">
    <carbon-logo-github />
  </a>
</div>


<!--
The last comment block of each slide will be treated as slide notes. It will be visible and editable in Presenter Mode along with the slide. [Read more in the docs](https://sli.dev/guide/syntax.html#notes)
-->

---

# Terraform とは？
<br>
<p><span>インフラストラクチャのビルド・変更を効率的に行うためのツール</span></p>

参考：[HashiCorp Terraform](https://www.terraform.io/)

## 同じレイヤのツール

- AWS CloudFormation
- Azure Resource Manager

<br>
<br>

<style>
span {
	font-size: 2em;
}
</style>


---

# Terraformの利点
<br>
<p><span>ローカル・リモート・複数クラウドのサービスをまとめて管理できる</span></p>

<p>この利点をもったツールとしては実質1強であるため、
学習リソースも豊富に転がっている。</p>

<style>
span {
	font-size: 2em;
}
</style>


---

# デモ - 概要
<br>

リポジトリ：[Polarbear08/terraform-examples](https://github.com/Polarbear08/terraform-examples)

AWSのインスタンスを作成する。(main/01_Single_EC2)

素晴らしい構成図

---

# デモ - まずは動かす

## 重要なファイル

|ファイル名|説明|
|:--|:--|
|main.tf|実際の構成を記述するファイル|
|variables.tf|変数を定義するファイル|
|outputs.tf|実行後の出力を定義するファイル|
|terraform.tfvars|terraformで使用する変数の値を設定するファイル|

## 実行の流れ

```sh
# 実行の確認
$ terraform plan

# 実行
$ terraform apply
```

---

# デモ - 何ができたか？

- VPC
- サブネット
- インターネットゲートウェイ
- ルーティングテーブル
- セキュリティグループ
- EC2インスタンス


---

# デモ - 何ができたか？

- VPC

```
# VPC
resource "aws_vpc" "sample01-vpc" {
  cidr_block = "10.101.0.0/16"

  tags = {
    Group = "sample01"
    Name  = "sample01-vpc"
  }
}
```

---

# デモ - 何ができたか？

- サブネット

```
resource "aws_subnet" "sample01-subnet01" {
  vpc_id                  = aws_vpc.sample01-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.101.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Group = "sample01"
    Name  = "sample01-subnet01"
  }
}
```

---

# デモ - 何ができたか？

- インターネットゲートウェイ

```
resource "aws_internet_gateway" "sample01-igw" {
  vpc_id = aws_vpc.sample01-vpc.id

  tags = {
    Group = "sample01"
    Name  = "sample01-igw"
  }
}
```

---

# デモ - 何ができたか？

- ルーティングテーブル

```
resource "aws_route_table" "sample01-routetable01" {
  vpc_id = aws_vpc.sample01-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sample01-igw.id
  }

  tags = {
    Group = "sample01"
    Name  = "sample01-routetable01"
  }
}

resource "aws_route_table_association" "sample01-association01" {
  subnet_id      = aws_subnet.sample01-subnet01.id
  route_table_id = aws_route_table.sample01-routetable01.id
}
```

---

# デモ - 何ができたか？

- セキュリティグループ(一部省略)

```
resource "aws_security_group" "sample01-sg01" {
  description = "allow SSH and HTTP from specific IP address"
  vpc_id      = aws_vpc.sample01-vpc.id
  ingress {
    description = "SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.local_ips
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Group = "sample01"
    Name  = "sample01-sg01"
  }
}
```

---

# デモ - 何ができたか？

- EC2インスタンス

```
resource "aws_instance" "sample01-instance01" {
  ami                         = local.image_id.centos7
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.sample01-keypair01.key_name
  vpc_security_group_ids      = [aws_security_group.sample01-sg01.id]
  subnet_id                   = aws_subnet.sample01-subnet01.id
  associate_public_ip_address = true

  tags = {
    Group = "sample01"
    Name  = "sample01-instance01"
  }
  volume_tags = {
    Group = "sample01"
    Name  = "sample01-volume01"
  }
```

---

# 後片付け

```sh
$ terraform destroy
```

---

# いわゆるIaCで考えなければならないこと

## ドリフト
コードで管理している状態と実際の状態が異なることを指す。

- そもそも状態をできる限り管理しない
- ソフトウェアの情報等はできるだけ他のツールに任せる

## ツールへの習熟

- ツールの導入と学習コストの増加は表裏一体である
- 特定少数しか構成を管理できなくなる危険性がある
- Webコンソールの手軽さとのトレードオフを考える

---

# 盛り込みたかったけどできなかった内容

- AWSのLinuxにデプロイしたアプリにAzureのWindowsクライアントからアクセスする環境の作成
  - 本当はこれをやりたかった
- ローカルを含む複数サーバで構成されるKubernetesクラスタの作成
  - 本当はこれもやりたかった

やりたいことに対する理解が追いついていない＼(^o^)／

基盤のインフラを見直す動きもあるようなので何か勉強会とかできたらいいですね(雑)


---

# 以上
