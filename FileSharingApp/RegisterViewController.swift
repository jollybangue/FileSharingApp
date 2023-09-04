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
        // Do any additional setup after loading the view.
        registerEmailTextField.placeholder = "Enter your email@rex.com"
        registerPasswordTextField.placeholder = "Password"
        registerPasswordTextField.isSecureTextEntry = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if let homeVC = segue.destination as? HomeViewController {
            
            // Pass the selected object to the new view controller.
            if let extractedUsername = sender as? String {
                homeVC.username = extractedUsername
            }
        }
    }
    
    
    @IBAction func createAccountButton(_ sender: UIButton) {
        
        guard let email = registerEmailTextField.text, !email.isEmpty,
              let password = registerPasswordTextField.text, !password.isEmpty else {
            /// Show alert to indicate that there is a problem.
            AlertManager.showAlert(myTitle: "Registration error", myMessage: "Email or password is empty")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, maybeError in
            
            if let error = maybeError {
                let authenticationErrorCode = AuthErrorCode.Code(rawValue: error._code)
                
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
            /// Handle successfull sign up
            self?.performSegue(withIdentifier: "registerToHomeScreen", sender: email)
            AlertManager.showAlert(myTitle: "Account created", myMessage: "Account created successfully")
        }
    }
    
    @IBAction func goToLoginButton(_ sender: UIButton) {
        performSegue(withIdentifier: "registerToLogin", sender: (Any).self)
    }
}
