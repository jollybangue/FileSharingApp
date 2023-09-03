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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if let homeVC = segue.destination as? HomeViewController {
            if let extractedUsername = sender as? String {
                homeVC.username = extractedUsername
            }
        }
        // Pass the selected object to the new view controller.
    }
    
    
    @IBAction func createAccountButton(_ sender: UIButton) {
        
        guard let email = registerEmailTextField.text, !email.isEmpty,
              let password = registerPasswordTextField.text, !password.isEmpty else {
            // Show alert to indicate that there is a problem.
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { _, maybeError in
//            if let error = maybeError {
//                let authenticationErrorCode = AuthErrorCode.Code(rawValue: error._code)
//                switch authenticationErrorCode {
//                case .emailAlreadyInUse:
//                    //self?.showAlert(myTitle: "Failed to create an account", myMessage: "The email address is already in use")
//
//                case .invalidEmail:
//                    //self?.showAlert(myTitle: "Failed to create an account", myMessage: "The email address is not valid")
//
//                case .weakPassword:
//                    //self?.showAlert(myTitle: "Failed to create an account", myMessage: "Password is too weak")
//
//                default:
//                    //self?.showAlert(myTitle: "Failed to create an account", myMessage: "Something wrong, please try again")
//                                                }
//                return
//            }
            /// Handle successfull sign up
            //self?.showAlert(myTitle: "Account created", myMessage: "Account created successfully")
            self.performSegue(withIdentifier: "registerToHomeScreen", sender: email)
        }
    }
    
    @IBAction func goToLoginButton(_ sender: UIButton) {
    }
    

}
