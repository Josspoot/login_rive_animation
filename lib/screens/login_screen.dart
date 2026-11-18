import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async';

import 'products_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;

  StateMachineController? _controller;
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  Timer? _typingDebounce;

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  String? emailError;
  String? passError;
  // General login error: it does not belong to a specific field
  String? authError;

  // 5.2 Loading state
  bool _isLoading = false;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  // 5.3 Async login
  Future<void> _onLogin() async {
    final email = emailCtrl.text.trim();
    final pass = passwordCtrl.text;

    final emailTypeError = isValidEmail(email) ? null : 'Email inválido';
    final passTypeError = isValidPassword(pass) ? null : 'Contraseña inválida';

    setState(() {
      emailError = emailTypeError;
      passError = passTypeError;
      authError = null;
    });

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    if (emailTypeError != null || passTypeError != null) {
      _trigFail?.fire();
      return;
    }

    // 5.4 Show the spinner
    setState(() {
      _isLoading = true;
    });

    try {
      // 5.5 Artificial delay so the spinner is visible, then Firebase validates
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // 5.6 Let the bear celebrate
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _trigSuccess?.fire();
      await Future.delayed(const Duration(seconds: 2));

      // 5.7 Replace the login so "back" does not return to it
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // 5.8 Wrong credentials: general message, no field is marked
      if (!mounted) return;
      const credentialCodes = {
        'invalid-credential',
        'wrong-password',
        'user-not-found',
        'invalid-email',
      };
      debugPrint('FirebaseAuth error: ${e.code}');
      setState(() {
        _isLoading = false;
        authError = credentialCodes.contains(e.code)
            ? 'Credenciales no válidas'
            : 'No se pudo iniciar sesión. Intenta de nuevo.';
      });
      _trigFail?.fire();
    }
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
          _numLook?.value = 50;
        }
      }
    });

    _passwordFocusNode.addListener(() {
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear-animation.riv',
                    stateMachines: ['Login Machine'],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      if (_controller == null) return;
                      artboard.addController(_controller!);
                      _isChecking = _controller?.findSMI('isChecking');
                      _isHandsUp = _controller?.findSMI('isHandsUp');
                      _trigSuccess = _controller?.findSMI('trigSuccess');
                      _trigFail = _controller?.findSMI('trigFail');
                      _numLook = _controller?.findSMI('numLook');
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  focusNode: _emailFocusNode,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //_isHandsUp!.change(false);
                    }
                    if (_isChecking != null) {
                      _isChecking!.change(true);
                      final look = (value.length / 70.0 * 100).clamp(
                        0.0,
                        100.0,
                      );
                      _numLook?.value = look;
                      _typingDebounce?.cancel();
                      _typingDebounce = Timer(const Duration(seconds: 3), () {
                        if (!mounted) return;
                        _isChecking?.change(false);
                      });
                    }
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: "email@ejemplo.com",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordCtrl,
                  focusNode: _passwordFocusNode,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      _isHandsUp!.change(true);
                    }
                    if (_isChecking != null) {
                      //_isChecking!.change(false);
                    }
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    errorText: passError,
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: size.width,
                  child: const Text(
                    "Al iniciar sesión, aceptas nuestras políticas de privacidad y términos de servicio.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),
                if (authError != null) ...[
                  Text(
                    authError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                ],
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.blue,
                  disabledColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textColor: Colors.white,
                  // 5.9 Spinner while Firebase answers
                  onPressed: _isLoading ? null : _onLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text("Iniciar sesión"),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: size.width,
                  child: Row(
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "register",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}
