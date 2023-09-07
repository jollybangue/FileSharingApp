//
//  HomeScreenViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-08-28.
//
/// Description: A native iOS app that enables users to upload, download, delete, and share files using Firebase features (Firebase Authentication and Firebase Cloud Storage).

import UIKit
import FirebaseAuth

class HomeViewController: UIViewController {
    
    // Later, I can add a label in Home screen to show the email of the currently logged in user and set the text with the value of userEmail...
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Disable in the Navigation Controller the "Back to previous screen" button (located at the top left)
        navigationItem.setHidesBackButton(true, animated: false)
        
        // I prefer not to show alerts here because it will also imply the management of if conditions
        // The alerts are directly triggered from Register or Login view controllers.
        
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("Message from Home View Controller: The current user is \(String(describing: Auth.auth().currentUser?.email))")
            return
        }
        print("Message from Home View Controller: The current user is \(userEmail)")
        
    }
    
    
    @IBAction func didTapUpload(_ sender: UIButton) {
    }
    
    
    @IBAction func didTapSignOut(_ sender: UIButton) {
        
        let confirmationAlert = UIAlertController(title: "Confirmation", message: "Do you want to sign out?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            do {
                try Auth.auth().signOut()
                self.performSegue(withIdentifier: "homeToLogin", sender: (Any).self)
            } catch (let error) {
                AlertManager.showAlert(myTitle: "Signing out failed", myMessage: error.localizedDescription)
            }
        }
        
        confirmationAlert.addAction(cancelAction)
        confirmationAlert.addAction(signOutAction)
        
        present(confirmationAlert, animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
