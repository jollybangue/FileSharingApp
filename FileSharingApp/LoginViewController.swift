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
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if let myHomeVC = segue.destination as? HomeViewController {
            
            // Pass the selected object to the new view controller.
            if let extractedUserName = sender as? String {
                myHomeVC.username = extractedUserName
            }
            
        }
    }

    @IBAction func signInButton(_ sender: UIButton) {
        
        guard let email = loginEmailTextField.text, !email.isEmpty,
              let password = loginPasswordTextField.text, !password.isEmpty else {
            /// Show here an alert saying that there is something wrong...
            AlertManager.showAlert(myTitle: "Login error", myMessage: "Email or password is empty")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, maybeError in
            
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
            self?.performSegue(withIdentifier: "loginToHome", sender: email)
        }
    }
    
    @IBAction func registerButton(_ sender: UIButton) {
        performSegue(withIdentifier: "loginToRegister", sender: (Any).self)
    }
    
}

