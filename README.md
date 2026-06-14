# オーラス条件トレーナー

「何点必要？」を一瞬でわかる麻雀力へ。

麻雀のオーラス・終盤で「あと何点アガれば順位が上がるか」をクイズ形式で反復練習する iOS アプリ（SwiftUI / iOS 17+ / 無料・通信不要・ログイン不要）。

---

## この README の使い方

**Mac を持っていなくても、Apple Developer 登録済みなら App Store 公開まで完走できます。**
コードは Windows で用意し、ビルド・署名・配信はクラウドの Mac（Codemagic）に肩代わりさせます。
壊れやすい `.xcodeproj` は手作業で作らず、`project.yml`（XcodeGen）からクラウド側で自動生成します。

```
Windows（このフォルダ） → GitHub に push
   → Codemagic（クラウド Mac）が XcodeGen で .xcodeproj 生成 → ビルド → 自動署名 → TestFlight 配信
      → iPhone の TestFlight アプリで実機テスト → App Store 申請
```

---

## プロジェクト構成

```
OorasuConditionTrainer/
├─ project.yml            … XcodeGen 設定（クラウドで .xcodeproj を自動生成）
├─ codemagic.yaml         … Codemagic CI/CD 設定（ビルド〜TestFlight）
├─ .gitignore
├─ README.md
└─ App/
   ├─ OorasuConditionTrainerApp.swift   … @main・ナビゲーション・セッションの入れ物
   ├─ Assets.xcassets/                  … アプリアイコン枠・アクセントカラー
   ├─ Models/
   │   ├─ Player.swift          … Wind / Player
   │   ├─ Question.swift        … QuestionMode / Question
   │   ├─ AnswerResult.swift    … 回答結果
   │   └─ UserStats.swift       … 累計成績
   ├─ Views/
   │   ├─ HomeView.swift
   │   ├─ ModeSelectView.swift
   │   ├─ QuestionView.swift
   │   ├─ ExplanationView.swift
   │   ├─ ResultView.swift
   │   ├─ HowToPlayView.swift
   │   └─ Components/
   │       ├─ ScoreBoardView.swift
   │       ├─ PlayerScoreRowView.swift
   │       ├─ ChoiceButtonView.swift
   │       ├─ StatsCardView.swift
   │       └─ PrimaryButton.swift
   ├─ ViewModels/
   │   ├─ QuizViewModel.swift   … 10問セッションの進行管理
   │   └─ StatsViewModel.swift  … 累計成績の供給
   ├─ Services/
   │   ├─ QuestionGenerator.swift … 問題生成ロジック
   │   ├─ ScoreCalculator.swift   … 点数条件の判定ロジック
   │   └─ StatsStorage.swift      … UserDefaults 永続化
   └─ Utilities/
       ├─ NumberFormatterUtility.swift … 「31,800」表記
       └─ Theme.swift                  … 配色（緑/白/黒＋赤/金・ダーク対応）
```

設計は MVVM。問題生成（QuestionGenerator）・点数判定（ScoreCalculator）・保存（StatsStorage）を分離しているので、
ツモ条件・直撃・本場供託あり・苦手復習などの新モードは `QuestionMode` に case を足して各 Service を拡張するだけで追加できます。

---

## ロジックの要点

### 点数条件の判定（ScoreCalculator）
- 対象者**以外**からロンすると、加点されるのは自分だけ。
- よって「自分の点数 ＋ ロン点 ＞ 対象者の点数」を満たす必要がある（同点は逆転不可なので**厳密に上回る**）。
- 実戦で使う点数候補（1,000〜32,000）の中から、`ロン点 > 点差` を満たす**最小**の候補を正解にする。

### 問題生成（QuestionGenerator）
- 合計 100,000 点・100 点単位・トビなし・重複なしのスコアをランダム生成。
- モードに応じて自分の順位（着順アップ=2〜4位 / ラス回避=4位 / トップ条件=2〜3位）と対象順位を決定。
- 点差が候補の範囲に収まる問題だけ採用（generate-and-check）。
- 4 択は正解＋近い候補（低い側・高い側を混ぜる）で構成。

---

## 事前に用意するもの（すべてブラウザ／Mac 不要）

1. **GitHub アカウント**（無料）
2. **Apple Developer Program**（登録済み）
3. **Codemagic アカウント**（https://codemagic.io ・GitHub でサインイン可）

---

## セットアップ手順

### STEP 1. GitHub にコードを上げる
このフォルダ（`OorasuConditionTrainer`）を GitHub の新規リポジトリに push します。
Windows の Git でも、GitHub Desktop でも、ブラウザのアップロードでも構いません。
例（Git の場合）:

```bash
cd OorasuConditionTrainer
git init
git add .
git commit -m "first commit: オーラス条件トレーナー MVP"
git branch -M main
git remote add origin https://github.com/<あなた>/OorasuConditionTrainer.git
git push -u origin main
```

### STEP 2. App Store Connect でアプリ枠を作る
1. https://appstoreconnect.apple.com → 「マイApp」→「＋」→ 新規 App
2. プラットフォーム: iOS / 名前: オーラス条件トレーナー / 言語: 日本語
3. **バンドル ID** を新規作成（例 `com.beqd1106.oorasutrainer`）。
   - `project.yml` と `codemagic.yaml` の `bundle_identifier` を、ここで作った ID に合わせてください（初期値は `com.beqd1106.oorasutrainer`）。

### STEP 3. App Store Connect API キーを発行
1. App Store Connect →「ユーザーとアクセス」→「Integrations（または鍵）」→ App Store Connect API
2. 「鍵を生成」→ アクセス権 **App Manager** → ダウンロード（`.p8`・**1 回しか落とせない**ので保管）
3. 表示される **Key ID** と **Issuer ID** を控える

### STEP 4. Codemagic に接続・登録
1. Codemagic にログイン → 「Add application」→ GitHub から本リポジトリを選択
2. ビルド設定は **「codemagic.yaml を使う」** を選択（本リポジトリに同梱済み）
3. **Teams → Integrations → App Store Connect** に STEP 3 の鍵を登録し、名前を **`AppStoreConnect`** にする（`codemagic.yaml` の `integrations:` と一致させる）
   - 自動コード署名（証明書・プロビジョニングプロファイルの作成）はこの API キー経由で Codemagic が自動で行います。**Mac での証明書作成は不要です。**

### STEP 5. ビルド実行
- `main` に push すると自動でビルドが走ります（手動で「Start new build」も可）。
- 成功すると **TestFlight に自動アップロード**されます（`submit_to_testflight: true`）。

---

## 動作確認（実機テスト）

1. iPhone に **TestFlight** アプリ（無料）をインストール
2. App Store Connect → 対象アプリ →「TestFlight」→ 自分を内部テスターに追加
3. メールの招待 or TestFlight アプリからインストールして実機で確認

確認したいポイント:
- ホームの「今日の練習」「各モード」から 10 問解ける
- 回答→解説→次へ→結果まで止まらず進む
- 結果の成績がホームの「通算正答率・平均回答時間・累計回答数」に反映される
- ダークモード（設定 → 画面表示と明るさ）で崩れない
- 縦持ち・片手で 4 択が押しやすい

> 補足: Codemagic のビルドログ画面でもシミュレータ動画やスクリーンショットの確認はできますが、**実機テストは TestFlight が確実**です。

---

## App Store 申請（TestFlight 確認後）

1. App Store Connect → 対象アプリ →「App Store」タブ →「+ バージョン」
2. 必要情報（下のチェックリスト）を入力
3. ビルドに TestFlight に上がっているビルドを選択
4. 「審査へ提出」

---

## App Store 公開に必要な準備物リスト

### 必須
- [ ] **アプリアイコン 1024×1024 PNG**（角丸・透過なし）
      → 作成後 `App/Assets.xcassets/AppIcon.appiconset/` に入れ、`Contents.json` の該当スロットに `"filename"` を追加。
      Windows でも Figma / Canva / フリー素材で作成可。麻雀牌や緑卓モチーフ＋アプリ名で OK。
- [ ] **スクリーンショット**（6.7インチ＝iPhone 15 Pro Max 等のサイズが最低 1 セット必要）
      → 実機 TestFlight 版で撮影、または Figma でフレームに合成。ホーム/出題/解説/結果の 4 枚程度。
- [ ] **アプリ名**：オーラス条件トレーナー
- [ ] **サブタイトル**（任意・30 字）：例「麻雀の着順条件を反復練習」
- [ ] **説明文**：機能・使い方を独自表現で（特定の対局アプリ/団体名は書かない）
- [ ] **キーワード**：麻雀, 点数計算, オーラス, 着順, 練習, 雀士 など
- [ ] **サポート URL**（簡単な案内ページで可。beqd1106.com 配下に 1 ページ用意すると楽）
- [ ] **プライバシーポリシー URL**
      → 本アプリは「データを収集しない（No data collected）」。App プライバシーで全項目「収集しない」を選択。
- [ ] **年齢区分**：ギャンブルなし（実際のお金を賭けないため。年齢設定で確認）
- [ ] **カテゴリ**：教育 もしくは ゲーム＞ボード/カード
- [ ] **輸出コンプライアンス**：暗号化なし（`Info.plist` に `ITSAppUsesNonExemptEncryption=false` 設定済み）

### 任意（あると良い）
- [ ] プロモーション用テキスト
- [ ] App プレビュー動画

---

## 著作権・審査メモ
- Mリーグ・雀魂など実在サービスのロゴ/画像/名称はアプリ内に**一切入れない**（コード・文言とも独自表現）。
- 実際の金銭を賭ける要素なし → ギャンブルアプリには該当しない方針。
- 計算機ではなく「練習・成績・解説のある学習アプリ」として作成済み。

---

## ローカルで build したくなったら（将来 Mac を使う場合）
```bash
brew install xcodegen
xcodegen generate          # OorasuConditionTrainer.xcodeproj が生成される
open OorasuConditionTrainer.xcodeproj
```
Windows のみの現状ではこの手順は不要です（Codemagic が代行）。
