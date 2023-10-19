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
        
        navigationController?.navigationBar.prefersLargeTitles = true

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
                AlertManager.showAlert(myTitle: "Login Error", myMessage: error.localizedDescription)
                return
            }
            
            /// Extraction of the user email
            guard let userEmail = Auth.auth().currentUser?.email else { // TODO: Save the user email in a static variable
                /// Printing a message test in console just for debugging
                print("Message from Login View Controller: The current user is \(String(describing: Auth.auth().currentUser?.email))")
                return
            }
            
            /// Printing a message test in console just for debugging
            print("Message from Login View Controller: The current user is \(userEmail)")
            
            /// Handling successfull login
            self?.performSegue(withIdentifier: "loginToHome", sender: self)
            AlertManager.showAlert(myTitle: "Welcome", myMessage: "Welcome \(userEmail)")
        }
    }
    
    @IBAction func didTapGoToRegister(_ sender: UIButton) {
        /// Moving to RegisterViewController
        performSegue(withIdentifier: "loginToRegister", sender: self) // There is no need to prepare the segue with override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
        
        /// Destroying the current view controller (LoginViewController). In that way, being in the new view controller (RegisterViewController), it will not be possible to back to this view controller (LoginViewController).
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
