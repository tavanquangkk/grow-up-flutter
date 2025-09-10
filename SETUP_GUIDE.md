# 別のPCでの開発環境セットアップ手順

## 📝 概要
このプロジェクトを別のPCで動かす際の手順を説明します。

## 🔧 セットアップ手順

### 1. プロジェクトのクローン・コピー
```bash
# GitHubからクローンする場合
git clone [リポジトリURL]
cd grow-up-app/frontend/grow_up

# またはプロジェクトフォルダをコピー
```

### 2. 新しいPCのIPアドレスを確認

**Windows の場合：**
```cmd
ipconfig | findstr "IPv4"
```

**Mac の場合：**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Linux の場合：**
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
```

例：`192.168.1.100` のような値が表示されます

### 3. APIConfig設定の変更
`lib/core/config/api_config.dart` ファイルを開き、`DEV_SERVER_IP` を新しいPCのIPアドレスに変更：

```dart
class ApiConfig {
  /// ⭐ ここを新しいPCのIPアドレスに変更してください
  static const String DEV_SERVER_IP = '192.168.1.100'; // <- 例：新しいIPアドレス
  
  // ... 他の設定はそのまま
}
```

### 4. バックエンドサーバーの起動
バックエンドサーバーを起動します：
```bash
# Spring Bootプロジェクトがある場所で
./gradlew bootRun
# または
java -jar target/your-backend-app.jar
```

**重要：** サーバーが全てのネットワークインターフェースでリッスンするよう設定されている必要があります：
- Spring Bootの場合：`server.address=0.0.0.0` を設定
- ポート8080が開いていることを確認

### 5. Flutterプロジェクトのセットアップ
```bash
flutter clean
flutter pub get
```

### 6. 動作確認

**シミュレータでテスト：**
```bash
flutter run
```
→ localhost経由でバックエンドに接続されるはず

**実機でテスト：**
```bash
flutter run -d [デバイスID]
```
→ 新しいPCのIPアドレス経由で接続されるはず

## 🐛 トラブルシューティング

### 1. 実機から接続できない場合
- iPhoneとPCが同じWi-Fiネットワークに接続されているか確認
- ファイアウォールでポート8080が開放されているか確認
- バックエンドサーバーが0.0.0.0でリッスンしているか確認

### 2. ネットワーク確認方法
**PCのブラウザでテスト：**
```
http://localhost:8080/api/v1/workshops
```

**iPhoneのSafariでテスト：**
```
http://[新しいPCのIPアドレス]:8080/api/v1/workshops
```

403エラーが表示されれば接続は正常（認証が必要なだけ）

### 3. デバッグログの確認
アプリ起動時にコンソールで以下のようなログが表示されます：
```
🔧 [API_CONFIG] 実機環境detected - Using URL: http://192.168.1.100:8080
🔧 [API_CONFIG] Platform.isIOS: true, Platform.isAndroid: false
```

## 📁 設定ファイルの場所
- メインの設定：`lib/core/config/api_config.dart`
- iOS HTTP設定：`ios/Runner/Info.plist`（NSAppTransportSecurity）

## ✅ 設定完了チェックリスト
- [ ] 新しいPCのIPアドレスを確認
- [ ] `api_config.dart` のIPアドレスを更新
- [ ] バックエンドサーバーが起動している
- [ ] `flutter clean && flutter pub get` を実行
- [ ] シミュレータで動作確認
- [ ] 実機で動作確認

---
**💡 ヒント：** IPアドレスは環境に応じて変わる可能性があります。新しいネットワークに移動した場合は、再度IPアドレスを確認して設定を更新してください。
