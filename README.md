# こよみシフト (iOSアプリ)

1画面に収まる勤怠カレンダー。デザインは女の子向けのパステルピンク基調。出勤・退勤の時間を入れるだけで、月の勤務時間の合計までひと目でわかる。日本の祝日表示 (2026年分) つき。
Macなしで App Store に出す前提で、クラウドビルド (Codemagic) 用の設定まで入れてある。

## アプリの内容
- 1画面完結: 月カレンダーの各日に「9:00-18:00」のように出勤-退勤を表示
- 日をタップすると下半分にその日の出勤・退勤・勤務時間を大きく表示
- 入力は出勤と退勤の2つだけ (休みワンタップ、メモ任意)
- 店名と本人の名前を設定でき、画面上に「○○さんの出勤予定 ・ 店名」と表示。店名は日ごとに変更も可能
- 「月表示」タブで1か月分の出勤予定を一覧でも確認できる (行タップで編集)
- 「週の調整」タブで1週間分を1タップでまとめて入力 (平日だけ/土日休み/全日休みなど)
- 曜日指定の一括入力も可能 (例: 今月の月・水・金すべてに同じ時間を入れる、出勤/休みの切替つき)
- 入力画面は大きなボタンと時間のワンタップ候補つき。勤務時間は入力中にその場で計算表示
- 退勤のあとの予定 (買い物・ごはん等) もその日の記録に付け加えられる
- 1日ごとの入力はカレンダー/月表示/週の調整の全画面から可能
- 今月の勤務時間の合計と出勤日数を自動計算して上部に表示
- 祝日は赤字+祝日名表示、データは端末内に保存 (アカウント登録なし)

## App Store 公開までの手順

### 1. Apple Developer Program に登録 (必須・年間99ドル)
- https://developer.apple.com/programs/ にアクセスして Apple ID で登録
- 登録が済むまで数日かかることがある

### 2. App Store Connect でアプリを作成
- https://appstoreconnect.apple.com → マイApp → 新規App
- プラットフォーム: iOS
- 名前: こよみシフト (下の掲載文案参照)
- バンドルID: com.metabo.calendar を選択 (なければ「バンドルID」画面で新規登録)
  - すでに使われていると言われたら、com.metabo.calendar2026 などに変えて、project.yml と codemagic.yaml の該当箇所も同じに直す

### 3. App Store Connect API キーを発行
- App Store Connect → ユーザーとアクセス → 統合 → App Store Connect API → 鍵を生成 (権限: Admin または App Manager)
- Issuer ID / Key ID / ダウンロードした .p8 ファイルの中身を控える

### 4. GitHub にこのフォルダをアップロード
- GitHub で新しいリポジトリを作り、このフォルダの中身をそのままアップロード

### 5. Codemagic に接続
- https://codemagic.io に GitHub アカウントでログインし、リポジトリを追加
- Teams > Integrations > App Store Connect で APIキーを登録 (名前は codemagic.yaml の `integrations: app_store_connect: codemagic` と合わせる)
- codemagic.yaml のワークフロー「iOS Release (App Store)」を実行
- 成功すると TestFlight にアプリが届く

### 6. TestFlight で自分の iPhone で確認 → 審査提出
- TestFlight アプリで動作確認
- App Store Connect でスクリーンショットと掲載文を用意して「審査へ提出」
- 審査は通常 数日〜1週間ほど

## 掲載文案 (App Store Connect にそのまま使える下書き)

- アプリ名: こよみシフト
- サブタイトル: 出勤・退勤がひと目でわかる勤怠カレンダー
- 説明文:
  出勤と退勤を入れるだけの、シンプルな勤怠カレンダー。
  ・1画面で月のシフトが全部見える (各日に出勤-退勤の時間を表示)
  ・今月の勤務時間の合計と出勤日数を自動で計算
  ・休みの日もワンタップで記録
  ・日本の祝日に対応 (祝日名も表示)
  ・アカウント登録なし、記録は端末の中だけに保存するので安心
  店名と名前を入れれば、誰の・どこのシフトかもひと目でわかります。
  打刻も承認もいらない、自分の勤務メモのためのアプリです。
- キーワード: 勤怠,シフト,出勤,退勤,勤務時間,カレンダー,祝日,シンプル,ピンク,かわいい
- 価格: 無料
- カテゴリ: 仕事効率化

## ファイル構成
- Sources/ … アプリ本体の Swift コード (SwiftUI)
- Assets.xcassets/ … アプリアイコン
- project.yml … XcodeGen 用のプロジェクト定義 (Codemagic がビルド時に .xcodeproj を生成)
- codemagic.yaml … クラウドビルド+TestFlight 提出の自動設定

## 注意
- 祝日データは2026年分。翌年分は Sources/Models/Holidays.swift に追加する
- Bundle ID (com.metabo.calendar) は仮のもの。自分のものに変える場合は project.yml / codemagic.yaml / App Store Connect の3か所を揃える
