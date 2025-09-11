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
