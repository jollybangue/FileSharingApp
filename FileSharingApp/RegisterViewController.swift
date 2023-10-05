//
//  RegisterViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-08-28.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var registerEmailTextField: UITextField!
    @IBOutlet weak var registerPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Disable in the Navigation Controller the "Back to previous screen" button (located at the top left)
        navigationItem.setHidesBackButton(true, animated: false)

    }
    
    /// Is "prepare for segue necessary in this case?"
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if let homeVC = segue.destination as? HomeViewController {
            
            // Pass the selected object to the new view controller.
//            if let extractedUsername = sender as? BooleanLiteralType {
//                homeVC.isNewUser = extractedUsername
//            }
        }
    }
    
    /// This function clear the textfields of the Register screen when moving to another screen.
    func clearRegisterTextFields() {
        registerEmailTextField.text = ""
        registerPasswordTextField.text = ""
    }
    
    @IBAction func didTapCreateAccount(_ sender: UIButton) {
        
        guard let email = registerEmailTextField.text, !email.isEmpty,
              let password = registerPasswordTextField.text, !password.isEmpty else {
            /// Show alert to indicate that there is a problem.
            AlertManager.showAlert(myTitle: "Registration error", myMessage: "Email or password is empty")
            return
        }
        
        /// Managing the creation of a new user (Register) using the Firebase Authentication feature.
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, maybeError in
            
            /// Handling sign up (Register) errors
            if let error = maybeError {
                let authenticationErrorCode = AuthErrorCode.Code(rawValue: error._code)
                
                // TODO: Instead of listing different cases, try just to extract the default error message thrown by Firebase Auth.

                switch authenticationErrorCode {
                    
                case .emailAlreadyInUse:
                    AlertManager.showAlert(myTitle: "Failed to create an account", myMessage: "The email address is already in use")

                case .invalidEmail:
                    AlertManager.showAlert(myTitle: "Failed to create an account", myMessage: "The email address is not valid")

                case .weakPassword:
                    AlertManager.showAlert(myTitle: "Failed to create an account", myMessage: "Password is too weak")

                default:
                    AlertManager.showAlert(myTitle: "Failed to create an account", myMessage: "Something wrong, please try again")
                                                }
                return
            }
            
            /// Extraction of the user email
            guard let userEmail = Auth.auth().currentUser?.email else {
                /// Printing a message test in console just for debugging
                print("Message from Register View Controller: The current user is \(String(describing: Auth.auth().currentUser?.email))")
                return
            }
            /// Printing a message test in console just for debugging
            print("Message from Register View Controller: The current user is \(userEmail)")
            
            /// Handling successfull registration
            self?.performSegue(withIdentifier: "registerToHomeScreen", sender: (Any).self)
            AlertManager.showAlert(myTitle: "Account created successfully", myMessage: "Welcome \(userEmail)")
            self?.clearRegisterTextFields()
        }
    }
    
    @IBAction func didTapGoToLogin(_ sender: UIButton) {
        performSegue(withIdentifier: "registerToLogin", sender: (Any).self)
        clearRegisterTextFields()
    }
}
