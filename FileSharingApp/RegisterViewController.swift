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
        
        navigationController?.navigationBar.prefersLargeTitles = true

    }
    
    @IBAction func didTapCreateAccount(_ sender: UIButton) {
        
        guard let email = registerEmailTextField.text, !email.isEmpty,
              let password = registerPasswordTextField.text, !password.isEmpty else {
            /// Show alert to indicate that there is a problem.
            AlertManager.showAlert(myTitle: "Registration error", myMessage: "Sorry, the Email or Password text field is empty.")
            return
        }
        
        /// Managing the creation of a new user (Register) using the Firebase Authentication feature.
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, maybeError in
            
            /// Handling sign up (Register) errors:
            if let error = maybeError {
                AlertManager.showAlert(myTitle: "Registration error", myMessage: error.localizedDescription)
                return
            }
            
            /// Extraction of the user email
            guard let userEmail = Auth.auth().currentUser?.email else { // TODO: Save the user email in a static variable
                /// Printing a message test in console just for debugging
                print("Message from Register View Controller: The current user is \(String(describing: Auth.auth().currentUser?.email))")
                return
            }
            /// Printing a message test in console just for debugging
            print("Message from Register View Controller: The current user is \(userEmail)")
            
            /// Handling successfull registration
            self?.performSegue(withIdentifier: "registerToHomeScreen", sender: self)
            AlertManager.showAlert(myTitle: "Account successfully created", myMessage: "Welcome \(userEmail).\nWe hope you will enjoy this File Sharing App!")
        }
    }
    
    @IBAction func didTapGoToLogin(_ sender: UIButton) {
        /// Moving to LoginViewController
        performSegue(withIdentifier: "registerToLogin", sender: self) // There is no need to prepare the segue with override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
        
        /// Destroying the current view controller (RegisterViewController). In that way, being in the new view controller (LoginViewController), it will not be possible to back to this view controller (RegisterViewController).
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
