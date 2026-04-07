import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../common/gaming_ui.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = 'Unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
        data: {'username': _registerUsernameController.text.trim()},
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = 'Unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.nunito(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText.toUpperCase(),
          prefixIcon: Icon(
            isPassword ? Icons.lock_outline : Icons.alternate_email,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    primary.withOpacity(0.05),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(seconds: 1),
                      child: Column(
                        children: [
                          Text(
                            'PATTERNMIND',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ACCESS GRANTED // SYSTEM READY',
                            style: GoogleFonts.shareTechMono(
                              color: primary.withOpacity(0.7),
                              letterSpacing: 2,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    NeonCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TabBar(
                            controller: _tabController,
                            indicatorColor: primary,
                            dividerColor: Colors.transparent,
                            labelColor: primary,
                            unselectedLabelColor: Colors.white38,
                            labelStyle: GoogleFonts.orbitron(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                            tabs: const [
                              Tab(text: 'LOGIN'),
                              Tab(text: 'INITIALIZE'),
                            ],
                          ),
                          const SizedBox(height: 32),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: SizedBox(
                              height: _tabController.index == 0 ? 240 : 320,
                              child: _isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(color: primary),
                                    )
                                  : TabBarView(
                                      controller: _tabController,
                                      children: [
                                        // Login Form
                                        FadeIn(
                                          child: Column(
                                            children: [
                                              _buildTextField(
                                                controller: _loginEmailController,
                                                labelText: 'Email',
                                              ),
                                              _buildTextField(
                                                controller: _loginPasswordController,
                                                labelText: 'Password',
                                                isPassword: true,
                                              ),
                                              if (_errorMessage != null) ...[
                                                Text(
                                                  'ERROR: ${_errorMessage!.toUpperCase()}',
                                                  style: GoogleFonts.shareTechMono(
                                                    color: Colors.redAccent,
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                              const Spacer(),
                                              NeonButton(
                                                label: 'Login',
                                                onPressed: _submitLogin,
                                                icon: Icons.vpn_key_outlined,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Register Form
                                        FadeIn(
                                          child: Column(
                                            children: [
                                              _buildTextField(
                                                controller: _registerUsernameController,
                                                labelText: 'Username',
                                              ),
                                              _buildTextField(
                                                controller: _registerEmailController,
                                                labelText: 'Email',
                                              ),
                                              _buildTextField(
                                                controller: _registerPasswordController,
                                                labelText: 'Password',
                                                isPassword: true,
                                              ),
                                              if (_errorMessage != null) ...[
                                                Text(
                                                  'ERROR: ${_errorMessage!.toUpperCase()}',
                                                  style: GoogleFonts.shareTechMono(
                                                    color: Colors.redAccent,
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                              const Spacer(),
                                              NeonButton(
                                                label: 'Create Account',
                                                onPressed: _submitRegister,
                                                icon: Icons.person_add_alt_1_outlined,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: Text(
                        'V1.0 // ENCRYPTED SESSION',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white24,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
