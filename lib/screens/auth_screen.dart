import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:chat_app/widgets/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLogin = true;
  var _isAuthenticating = false;
  final _formKey = GlobalKey<FormState>();

  var _enteredEmail = '';
  var _enteredPassword = '';
  String? _enteredUsername;
  File? _selectedImage;

  void _submit() async {
    if (!_formKey.currentState!.validate() ||
        !_isLogin && _selectedImage == null) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isAuthenticating = true;
    });

    try {
      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUsername,
          'image_url': imageUrl,
          'email': _enteredEmail,
        });
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authentication failed.')));

      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
          child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              width: 200,
              child: Image.asset('assets/images/chat.png'),
            ),
            Card(
              margin: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isLogin)
                          UserImagePicker(
                            onPickImage: (image) {
                              _selectedImage = image;
                            },
                          ),
                        TextFormField(
                          decoration: const InputDecoration(
                            label: Text('Email Address'),
                          ),
                          autocorrect: false,
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                !value.contains('@')) {
                              return 'Please enter a valid email address.';
                            }
                          },
                          onSaved: (newValue) {
                            _enteredEmail = newValue!;
                          },
                        ),
                        if (!_isLogin)
                          TextFormField(
                            decoration: const InputDecoration(
                              label: Text('Username'),
                            ),
                            enableSuggestions: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null || value.trim().length < 4) {
                                return 'Please enter at least 4 characters.';
                              }
                            },
                            onSaved: (newValue) {
                              _enteredUsername = newValue!;
                            },
                          ),
                        TextFormField(
                          decoration: const InputDecoration(
                            label: Text('Password'),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return 'Password must be at least 6 characters long.';
                            }
                          },
                          onSaved: (newValue) {
                            _enteredPassword = newValue!;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (!_isAuthenticating)
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer),
                            child: Text(_isLogin ? 'Login' : 'Signup'),
                          ),
                        if (!_isAuthenticating)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(_isLogin
                                ? 'Create an account'
                                : 'I already have an account'),
                          ),
                        if (_isAuthenticating)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 8),
                            child: CircularProgressIndicator(),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
