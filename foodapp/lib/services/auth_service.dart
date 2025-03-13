import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Admin credentials
  final String _adminEmail = "admin@gmail.com";
  final String _adminPassword = "admin1234";

  // Check if a user is an admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['isAdmin'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint("Error checking admin status: ${e.toString()}");
      return false;
    }
  }

  // Create admin user if it doesn't exist
  Future<void> ensureAdminExists() async {
    try {
      // Check if admin already exists by email
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('email', isEqualTo: _adminEmail)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        debugPrint("Admin user does not exist. Creating...");
        try {
          // Create admin user in Firebase Auth
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: _adminEmail,
            password: _adminPassword,
          );

          User? user = userCredential.user;
          if (user != null) {
            // Create admin in Firestore
            UserModel adminUser = UserModel(
              uid: user.uid,
              email: _adminEmail,
              name: "Admin User",
              contactNumber: "",
              profilePicture: "",
              isAdmin: true,
            );

            await _firestore.collection('users').doc(user.uid).set(adminUser.toMap());
            debugPrint("Admin user created successfully");
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            debugPrint("Admin email exists in Auth but not in Firestore. Fetching user...");
            // Admin exists in Auth but not in Firestore
            try {
              UserCredential userCredential = await _auth.signInWithEmailAndPassword(
                email: _adminEmail,
                password: _adminPassword,
              );
              
              User? user = userCredential.user;
              if (user != null) {
                // Create admin in Firestore
                UserModel adminUser = UserModel(
                  uid: user.uid,
                  email: _adminEmail,
                  name: "Admin User",
                  contactNumber: "",
                  profilePicture: "",
                  isAdmin: true,
                );

                await _firestore.collection('users').doc(user.uid).set(adminUser.toMap());
                debugPrint("Admin user added to Firestore");
                
                // Sign out after creating admin
                await _auth.signOut();
              }
            } catch (signInError) {
              debugPrint("Error signing in as admin: ${signInError.toString()}");
            }
          } else {
            debugPrint("Error creating admin user: ${e.code} - ${e.message}");
          }
        }
      } else {
        // Admin already exists, ensure isAdmin flag is true
        String adminUid = result.docs.first.id;
        await _firestore.collection('users').doc(adminUid).update({'isAdmin': true});
        debugPrint("Admin user already exists");
      }
    } catch (e) {
      debugPrint("Error ensuring admin exists: ${e.toString()}");
    }
  }

  // Update user details
  Future<bool> updateUserDetails(
    String uid,
    String name,
    String contactNumber,
    String profilePicture,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'contactNumber': contactNumber,
        'profilePicture': profilePicture,
      });
      return true;
    } on FirebaseException catch (e) {
      debugPrint("Firebase Error: ${e.message}");
      return false;
    } catch (e) {
      debugPrint("Unexpected Error: ${e.toString()}");
      return false;
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String contactNumber,
    String profilePicture,
  ) async {
    try {
      // Validate email
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email address');
      }

      // Validate password
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }

      debugPrint("Attempting to create user in Firebase Auth...");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        debugPrint("User created in Firebase Auth: ${user.uid}");

        // Regular users are never admins when they register
        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          contactNumber: contactNumber,
          profilePicture: profilePicture,
          isAdmin: false, // Regular users are never admins
        );

        debugPrint("Saving user to Firestore...");
        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          debugPrint("Weak password error");
          throw Exception('The password is too weak.');
        case 'email-already-in-use':
          debugPrint("Email already in use error");
          throw Exception('An account already exists with this email.');
        case 'invalid-email':
          debugPrint("Invalid email error");
          throw Exception('The email address is not valid.');
        default:
          debugPrint("Firebase Auth Error: ${e.message}");
          throw Exception('Authentication failed. Please try again.');
      }
    } catch (e) {
      debugPrint("Unexpected Error: ${e.toString()}");
      throw Exception(e.toString());
    }
    return null;
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Auth Error: ${e.message}");
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      debugPrint("Unexpected Error: ${e.toString()}");
      throw Exception('An unexpected error occurred');
    }
    return null;
  }

  // Google Sign-In
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Begin the sign-in process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      // If user cancels the sign-in process
      if (googleUser == null) {
        debugPrint("Google Sign-In cancelled by user");
        return null;
      }

      // Obtain the auth details from the sign-in attempt
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Check if the user already exists in Firestore
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

        // If this is a new user, save their information
        if (!doc.exists) {
          // Google users are never admins by default
          UserModel userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            contactNumber: '',  // Google doesn't provide contact number
            profilePicture: user.photoURL ?? '',
            isAdmin: false, // Google users are never admins by default
          );
          
          await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
          debugPrint("New Google user created in Firestore: ${user.uid}");
          return userModel;
        }

        // If the user already exists, return their data
        debugPrint("Existing Google user found in Firestore: ${user.uid}");
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        debugPrint("Failed to get user data from Google Sign-In");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error during Google Sign-In: ${e.code} - ${e.message}");
      throw Exception(e.message ?? 'Google authentication failed');
    } on Exception catch (e) {
      debugPrint("Google Sign-In Error: ${e.toString()}");
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint("Password Reset Error: ${e.message}");
      throw Exception(e.message ?? 'Password reset failed');
    } catch (e) {
      debugPrint("Unexpected Error: ${e.toString()}");
      throw Exception('An unexpected error occurred');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Sign Out Error: ${e.toString()}");
      throw Exception('Sign out failed');
    }
  }

  // Email validation helper method
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }


   // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Fetch all registered users excluding the admin
  Future<List<UserModel>> getAllUsersExcludingAdmin() async {
    try {
      // Query the 'users' collection in Firestore
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();

      // Convert the documents to UserModel objects and filter out the admin
      List<UserModel> users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => !user.isAdmin && user.email != _adminEmail) // Exclude admin
          .toList();

      return users;
    } catch (e) {
      debugPrint("Error fetching all users: ${e.toString()}");
      throw Exception('Failed to fetch users: ${e.toString()}');
    }
  }

}