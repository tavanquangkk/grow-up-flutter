import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/core/utils/apis/auth_api_service.dart';
import 'package:grow_up/core/theme/app_colors.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _SignupState();
}

class _SignupState extends State<Register> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmController.text) {
      _showErrorDialog('パスワードが一致しません');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (res['status'] == 'success') {
        _showSuccessDialog('登録が完了しました！ログイン画面に移動します。');
      } else {
        _showErrorDialog(res['message'] ?? '登録に失敗しました');
      }
    } catch (e) {
      _showErrorDialog('ネットワークエラーが発生しました');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('エラー', style: TextStyle(color: AppColors.error)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('成功', style: TextStyle(color: AppColors.success)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              context.go('/login');
            },
            child: const Text('ログインへ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 左スワイプ戻りを無効化（誤操作防止）
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40),

                    // Header - 戻るボタン
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Logo Section
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          // Skill Share Logo Design
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: Offset(0, 15),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.secondary,
                                    AppColors.primary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Icon(
                                      Icons.person_add,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Positioned(
                                    top: 15,
                                    right: 15,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.trending_up,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 15,
                                    left: 15,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Icon(
                                        Icons.stars,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 28),
                          Text(
                            'GrowUpに参加',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'スキルを共有して成長しよう',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '名前を入力してください';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'フルネーム',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'メールアドレスを入力してください';
                        }
                        if (!value.contains('@')) {
                          return '有効なメールアドレスを入力してください';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'メールアドレス',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'パスワードを入力してください';
                        }
                        if (value.length < 6) {
                          return 'パスワードは6文字以上で入力してください';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'パスワード',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'パスワードの確認を入力してください';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'パスワード確認',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Register Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('アカウント作成'),
                    ),

                    SizedBox(height: 32),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '既にアカウントをお持ちの場合は ',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go("/login");
                          },
                          child: Text('ログイン'),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ); // WillPopScopeの閉じ括弧
  }
}
