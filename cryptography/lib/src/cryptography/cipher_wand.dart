// Copyright 2019-2020 Gohilla.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';
import 'dart:typed_data';

import '../../cryptography.dart';

/// An opaque object that has some secret key and support for [encrypt]
/// and/or [decrypt].
///
/// The secret key is not extractable.
///
/// ## Example
/// ```dart
/// import 'package:cryptography/cryptography.dart';
///
/// Future<void> main() async {
///   final cipher = Chacha20.poly1305Aead();
///   final secretKey = await cipher.newSecretKey();
///   final wand = await cipher.newCipherWandFromSecretKey(secretKey);
///
///   // Encrypt
///   final secretBox = await wand.encrypt([1,2,3]);
///
///   print('Nonce: ${secretBox.nonce}');
///   print('Cipher text: ${secretBox.cipherText}');
///   print('MAC: ${secretBox.mac.bytes}');
///
///   // Decrypt
///   final clearText = await wand.decrypt(secretBox);
/// }
/// ```
abstract class CipherWand extends Wand {
  /// Constructor for subclasses.
  CipherWand.constructor();

  /// Decrypts a [SecretBox] and returns the clear text.
  ///
  /// See [Cipher.decrypt] for more information.
  ///
  /// ## Example
  /// ```dart
  /// import 'package:cryptography/cryptography.dart';
  ///
  /// Future<void> main() async {
  ///   final cipher = Chacha20.poly1305Aead();
  ///   final secretKey = await cipher.newSecretKey();
  ///   final wand = await cipher.newCipherWandFromSecretKey(secretKey);
  ///
  ///   // Encrypt
  ///   final secretBox = await wand.encrypt([1,2,3]);
  ///
  ///   print('Nonce: ${secretBox.nonce}');
  ///   print('Cipher text: ${secretBox.cipherText}');
  ///   print('MAC: ${secretBox.mac.bytes}');
  ///
  ///   // Decrypt
  ///   final clearText = await wand.decrypt(secretBox);
  /// }
  /// ```
  Future<List<int>> decrypt(
    SecretBox secretBox, {
    List<int> aad = const <int>[],
    Uint8List? possibleBuffer,
  });

  /// Calls [decode] and then converts the bytes to a string by using
  /// [utf8] codec.
  Future<String> decryptString(SecretBox secretBox) async {
    final clearText = await decrypt(secretBox);
    try {
      return utf8.decode(clearText);
    } finally {
      // Cut the amount of possibly sensitive data in the heap.
      // This should be a cheap operation relative to decryption.
      clearText.fillRange(0, clearText.length, 0);
    }
  }

  /// Encrypts the [clearText] and returns the [SecretBox].
  ///
  /// See [Cipher.encrypt] for more information.
  ///
  /// ## Example
  /// ```dart
  /// import 'package:cryptography/cryptography.dart';
  ///
  /// Future<void> main() async {
  ///   final cipher = Chacha20.poly1305Aead();
  ///   final secretKey = await cipher.newSecretKey();
  ///   final wand = await cipher.newCipherWandFromSecretKey(secretKey);
  ///
  ///   // Encrypt
  ///   final secretBox = await wand.encrypt([1,2,3]);
  ///
  ///   print('Nonce: ${secretBox.nonce}');
  ///   print('Cipher text: ${secretBox.cipherText}');
  ///   print('MAC: ${secretBox.mac.bytes}');
  ///
  ///   // Decrypt
  ///   final clearText = await wand.decrypt(secretBox);
  /// }
  /// ```
  Future<SecretBox> encrypt(
    List<int> clearText, {
    List<int>? nonce,
    List<int> aad = const <int>[],
    Uint8List? possibleBuffer,
  });

  /// Converts a string to bytes using [utf8] codec and then calls [encrypt].
  Future<SecretBox> encryptString(String clearText) async {
    final bytes = utf8.encode(clearText);
    final secretBox = await encrypt(
      bytes,
      possibleBuffer: bytes is Uint8List ? bytes : null,
    );

    // Cut the amount of possibly sensitive data in the heap.
    // This should be a cheap operation relative to encryption.
    final cipherText = secretBox.cipherText;
    if (bytes is! Uint8List ||
        cipherText is! Uint8List ||
        !identical(bytes.buffer, cipherText.buffer)) {
      bytes.fillRange(0, bytes.length, 0);
    }

    return secretBox;
  }
}