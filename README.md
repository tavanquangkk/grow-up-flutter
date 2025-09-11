<div align="center">

# grow_up (Frontend)

学習スキル共有 / フォロー / DM(メール表示) 機能を持つ Flutter アプリ

</div>

## ✨ 主な機能
- ユーザープロフィール閲覧 / 自分と他人で表示制御
- 学習中(Learning) / 教えられる(Teachable) スキル登録
- フォロー / フォロワー一覧 + 動的カウント
- DM ボタン（相手メール表示 & コピー）
- アクセス & リフレッシュトークンによる認証維持
- 自分のプロフィール編集 (名前 / 部署 / 役職 / 自己紹介)
 - プロフィール画像変更（ギャラリー / カメラ アップロード）

## 🛠 技術スタック
| 分類 | 使用技術 |
|------|-----------|
| UI | Flutter (Material) |
| ルーティング | go_router |
| HTTP | http package |
| 永続化 | SharedPreferences / flutter_secure_storage(refresh) |
| 認証 | JWT (Access + Refresh) |

## 🔐 認証アーキテクチャ概要
```
┌────────────┐    login            ┌────────────┐
│  Flutter    │ ───────────────▶   │  Backend    │
│  (ApiService)│  token,refresh    │  /api/v1/auth│
└─────┬────────┘ ◀──────────────  └────┬─────────┘
			│ access 使用                     │
			│ GET /users/... (401?)          │
			│                                │
			│ 401 → refresh                  │
			├──────── POST /auth/refresh ───▶│ validates refresh
			│ ◀──────── newAccessToken       │
			│ retry 1 回                     │
			│ 失敗: onAuthExpired()          │
```

### 自動更新の流れ
1. リクエスト前にアクセストークンの exp をデコード
2. 期限 30 秒前なら proactive refresh
3. 401 受信時: refresh → 成功なら 1 回だけ元リクエスト再送
4. refresh 失敗 or 再送後も 401 → トークン削除 & `onAuthExpired` コールバック発火

### コールバック設定例 (main.dart 等)
```dart
ApiService.onAuthExpired = () {
	// 重複遷移防止フラグを適宜
	router.go('/login');
	// SnackBar などで "セッションが切れました" を表示
};
```

## 🧩 ディレクトリ概要
```
lib/
	main.dart
	core/
		config/        # APIエンドポイント設定
		utils/
			apis/        # ApiService (認証ロジック集約)
			auth/        # token_store, jwt_utils
	features/
		auth/          # 認証画面(ログイン等)
		home/          # ホーム / プロフィール / フォロー関連
```

## 📦 トークン保管ポリシー
| 種類 | 保存場所 | 備考 |
|------|----------|------|
| Access Token | SharedPreferences (短期) | 期限短い / 盗難影響小さめ |
| Refresh Token | flutter_secure_storage | Keychain / Keystore 上 |
| userId | SharedPreferences | 軽量識別 |

`CompositeTokenStore` により refresh のみセキュアストレージへ。切り替え: 
```dart
ApiService.setTokenStore(SharedPrefsTokenStore()); // すべてPrefs (開発用)
```

## 🧪 テスト容易性
```dart
ApiService.httpClient = MockClient((req) async { /* stub */ });
ApiService.setTokenStore(InMemoryStore()); // 独自実装
ApiService.resetCache();
```

## 🚀 セットアップ
```bash
flutter pub get
flutter run
```

バックエンドが `http://localhost:8080` で起動していることを確認してください。デバイス実機利用時は `api_config.dart` の `DEV_SERVER_IP` を自ホストIPへ変更。

## 🔄 主な API (一部)
| 用途 | メソッド | エンドポイント |
|------|----------|----------------|
| 登録 | POST | /api/v1/auth/register |
| ログイン | POST | /api/v1/auth/login |
| リフレッシュ | POST | /api/v1/auth/refresh |
| 自ユーザ Followings | GET | /api/v1/users/me/followings |
| 自ユーザ Followers | GET | /api/v1/users/me/followers |
| 指定ユーザーをフォロー | POST | /api/v1/users/me/follow/{id} |
| 指定ユーザーを解除 | DELETE | /api/v1/users/me/follow/{id} |

### フォロー機能実装メモ
`RecommendedUsersSection` で以下を実装:
- 初期表示時に `HomePageApiService.fetchFollowingIds()` で自分が既にフォローしているユーザーID集合を取得し O(1) 判定
- フォローボタン: 押下で即座に楽観的に「フォロー中」表示へ変更 → API 失敗時 SnackBar + ロールバック
- 解除ボタン (Outlined / グレー): 押下でフォロー解除を楽観的反映 → 失敗時ロールバック
- 個別ユーザー処理中はインジケータ表示・他操作無効化 (`_processingUserId`)
- フォロー中集合は `Set<String>` で保持し重複防止と高速判定

利用箇所差し替え例 (旧):
```dart
RecommendedUsersSection(future: HomePageApiService.getRecommendedUsers())
```
※ 既存引数そのまま利用可能 / 追加設定不要。

エラーパターン:
| ケース | UI 挙動 |
|--------|---------|
| フォローAPI 4xx/5xx | SnackBar: フォローに失敗しました + 元に戻す |
| 解除API 失敗 | SnackBar: フォロー解除に失敗しました + 元に戻す |
| 初期 followingIds 取得失敗 | すべて未フォロー表示 (ログに警告) |

### プロフィール編集機能
`ProfileScreen` (自分の画面時のみ) 右側に編集アイコンが表示され、`EditProfileScreen` へ遷移。

更新API:
```
PUT /api/v1/users/me
{
	"name": "のび太君",
	"department": "開発部",
	"position": "バックエンドエンジニア",
	"introduction": "Spring BootでのAPI開発が得意です。最近はFlutterを勉強中。"
}
```
成功レスポンス例:
```
{
	"status": "success",
	"message": "更新に成功しました",
	"data": { ... 更新後プロフィール ... }
}
```
フロー:
1. アイコンタップ → `EditProfileScreen` へ (初期値は取得済 userData)
2. 保存押下でバリデーション → `HomePageApiService.updateMyProfile()` 実行
3. 成功: SnackBar 表示 + `Navigator.pop(updatedData)` → 呼び出し元で `_refreshProfile()` 再取得
4. 失敗: SnackBar でエラー表示 (楽観更新なし)

バリデーション: 名前必須 / 他任意。キャンセルは戻るボタン。

### プロフィール画像変更
フロー:
1. 自分のプロフィール画像をタップ
2. 下からボトムシート: ギャラリー / カメラ いずれか選択
3. プレビュー表示後「更新する」押下 → `POST /api/v1/users/me/avatar`
4. 成功: SnackBar + 再取得 (画像反映)
5. 失敗: SnackBar でエラー

実装ポイント:
- MultipartRequest (フィールド名: `file`)
- 画像は maxWidth 1024 / imageQuality 85 で軽量化
- 失敗メッセージはサーバー `message` 優先
- 他人プロフィールではアップロード UI 非表示

トラブルシュート:
| 症状 | 対処 |
|------|------|
| 画像選択シートで何も起きない (iOS) | Info.plist に Camera / Photo Library UsageDescription があるか確認 |
| Permission Denied (Android) | AndroidManifest に CAMERA / READ_MEDIA_IMAGES 権限が入っているか、設定→アプリで許可 |
| 撮影後戻っても反映されない | 画像取得時 null (キャンセル) の可能性。ログ / SnackBar を確認 |
| 大きい画像で失敗 | リサイズ済みか (maxWidth 1024) を確認し再試行 |



## ⚠️ エラーハンドリング戦略
| 状況 | 挙動 |
|------|------|
| 401 (初回) | refresh 試行 |
| refresh 失敗 | トークン削除 + onAuthExpired |
| 401 (再試行後) | 同上 |
| 408 / 429 / 5xx | 指数バックオフ (最大3回) |
| JSON 不正 | 汎用エラーマップ返却 |

## 🔐 セキュリティ留意点
- refreshToken は可能な限り流出を防ぐ (secure storage)
- アクセストークンは短命を前提 (BE 側 TTL 推奨 5〜15分)
- ルートJailbreak検知等は今後の拡張余地
- ログにトークン値そのものは出力しない

## 🛠 よくある変更
| 目的 | 変更箇所 |
|------|----------|
| proactive 閾値変更 | `ApiService._kProactiveRefreshThreshold` |
| Token保存方式変更 | `ApiService.setTokenStore(...)` |
| リトライ回数調整 | `_withRetry(maxAttempts: ...)` 呼び出し側改修 (必要なら引数化) |
| 認証失効UI | `ApiService.onAuthExpired` コールバック設定 |

## 🗺 今後のアイデア
- Web / Desktop 対応のセッション分離
- GraphQL 化 (Batching / Subscriptions)
- オフラインキャッシュ層

## 📄 ライセンス
Private / Internal Use Only (必要なら追記)

---
開発支援: 認証やストレージ構成の追加改善が必要な場合は Issue / PR / 相談してください。
