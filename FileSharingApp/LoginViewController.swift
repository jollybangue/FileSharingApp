//
//  ViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-08-27.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginEmailTextField: UITextField!
    @IBOutlet weak var loginPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Disable in the Navigation Controller the "Back to previous screen" button (located at the top left)
        navigationItem.setHidesBackButton(true, animated: false)

    }
    
    /// Is "prepare for segue necessary in this case?"
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
//        if let myHomeVC = segue.destination as? HomeViewController {
//
//            // Pass the selected object to the new view controller.
//            if let extractedUserName = sender as? String {
//                myHomeVC.username = extractedUserName
//            }
//        }
    }
    
    /// This function clear the textfields of the Login screen when moving to another screen.
    func clearLoginTextFields() {
        loginEmailTextField.text = ""
        loginPasswordTextField.text = ""
    }

    @IBAction func didTapSignIn(_ sender: UIButton) {
        
        guard let email = loginEmailTextField.text, !email.isEmpty,
              let password = loginPasswordTextField.text, !password.isEmpty else {
            /// Show an alert saying that there is something wrong...
            AlertManager.showAlert(myTitle: "Login error", myMessage: "Email or password is empty")
            return
        }
        
        /// Managing the authentication and login of an existing user, by using the Firebase Authentication feature.
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, maybeError in
            
            /// Handling login errors
            if let error = maybeError {
                let authenticationErrorCode = AuthErrorCode.Code(rawValue: error._code)
                
                switch authenticationErrorCode {

                case .invalidEmail:
                    AlertManager.showAlert(myTitle: "Login Failed", myMessage: "The email address is not valid")

                case .wrongPassword:
                    AlertManager.showAlert(myTitle: "Login Failed", myMessage: "The password is not correct")

                case .userNotFound:
                    AlertManager.showAlert(myTitle: "Login Failed", myMessage: "There is no account for this email id")

                case .userDisabled:
                    AlertManager.showAlert(myTitle: "Login Failed", myMessage: "Your account has been disabled")

                default:
                    AlertManager.showAlert(myTitle: "Login Failed", myMessage: "Please check your email and password")
                }
                
                return
            }
            
            /// Extraction of the user email
            guard let userEmail = Auth.auth().currentUser?.email else {
                /// Printing a message test in console just for debugging
                print("Message from Login View Controller: The current user is \(String(describing: Auth.auth().currentUser?.email))")
                return
            }
            
            /// Printing a message test in console just for debugging
            print("Message from Login View Controller: The current user is \(userEmail)")
            
            /// Handling successfull login
            self?.performSegue(withIdentifier: "loginToHome", sender: (Any).self)
            AlertManager.showAlert(myTitle: "Welcome", myMessage: "Welcome \(userEmail)")
            self?.clearLoginTextFields()
        }
    }
    
    @IBAction func didTapGoToRegister(_ sender: UIButton) {
        performSegue(withIdentifier: "loginToRegister", sender: (Any).self)
        clearLoginTextFields()
    }
}
