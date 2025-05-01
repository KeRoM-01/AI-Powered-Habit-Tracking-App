// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, sort_child_properties_last, file_names, prefer_const_literals_to_create_immutables, avoid_print, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String email = '';
  String password = '';

  Future signIn() async {
    EasyLoading.show(status: 'Logging in...');
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      EasyLoading.dismiss();
      Navigator.of(context).pushNamed('/homeScreen');
    } on FirebaseAuthException catch (e) {
      EasyLoading.dismiss();
      if (e.code == 'user-not-found') {
        EasyLoading.showError('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        EasyLoading.showError('Wrong password provided for that user.');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError(e.toString());
    }
  }

  void openSignupScreen() {
    Navigator.of(context).pushReplacementNamed('/signupScreen');
  }

  // Future<void> _signInWithGoogle() async {
  //   EasyLoading.show(status: 'Signing in with Google...');
  //   try {
  //     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //     if (googleUser == null) {
  //       EasyLoading.dismiss();
  //       return; // The user canceled the sign-in
  //     }

  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;
  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     await FirebaseAuth.instance.signInWithCredential(credential);
  //     EasyLoading.dismiss();
  //     Navigator.of(context).pushNamed('/homeScreen');
  //   } catch (e) {
  //     EasyLoading.dismiss();
  //     EasyLoading.showError(e.toString());
  //   }
  // }

  Future<void> _signInWithGoogle() async {
  EasyLoading.show(status: 'Signing in with Google...');
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      EasyLoading.dismiss();
      return; // User canceled sign-in
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
    EasyLoading.dismiss();
    Navigator.of(context).pushNamed('/homeScreen');
  } catch (e) {
    EasyLoading.dismiss();
    EasyLoading.showError(e.toString());
  }
}


  // Future<void> _signInWithApple() async {
  //   EasyLoading.show(status: 'Signing in with Apple...');
  //   try {
  //     final appleCredential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //     );

  //     final oauthCredential = OAuthProvider("apple.com").credential(
  //       idToken: appleCredential.identityToken,
  //       accessToken: appleCredential.authorizationCode,
  //     );

  //     await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  //     EasyLoading.dismiss();
  //     Navigator.of(context).pushNamed('/homeScreen');
  //   } catch (e) {
  //     EasyLoading.dismiss();
  //     EasyLoading.showError(e.toString());
  //   }
  // }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //image
                SizedBox(height: 30),
                Image.asset('assets/cover.png', height: 150, width: 550),
                SizedBox(height: 20),

                //title
                Text(
                  'Sign In',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                //subtitle
                Text(
                  'SignIn to your account',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.black),
                ),

                SizedBox(height: 20),
                //email
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 10),

                //password
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                    ),
                  ),
                ),

                //button
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: signIn,
                    child: Container(
                      child: TextButton(
                        onPressed: signIn,
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          minimumSize: Size(300, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      //text
                    ),
                  ),
                ),

                SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google button
                    GestureDetector(
                      onTap: _signInWithGoogle,
                      child: Image.asset(
                        'assets/google.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                    SizedBox(width: 25),
                    // Apple button
                    // GestureDetector(
                    //   onTap: _signInWithApple,
                    //   child: Image.asset(
                    //     'assets/apple.png',
                    //     height: 40,
                    //     width: 50,
                    //   ),
                    // ),
                  ],
                ),

                // SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Not a member?'),
                    TextButton(
                      child: GestureDetector(
                        onTap: openSignupScreen,
                        child: Text(
                          'Register now',
                          style: GoogleFonts.poppins(
                            color: Color.fromARGB(255, 48, 29, 218),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
