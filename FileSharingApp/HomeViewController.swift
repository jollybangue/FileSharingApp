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
    
    
    @IBOutlet weak var homeTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        homeTableView.dataSource = self
        
        /// Disable in the Navigation Controller the "Back to previous screen" button (located at the top left)
        navigationItem.setHidesBackButton(true, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // I prefer NOT to show alerts here because it will also imply the management of if conditions
        // The alerts are directly triggered from Register or Login view controllers.
        
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("Message from Home View Controller: The current user is \(String(describing: Auth.auth().currentUser?.email))")
            return
        }
        print("Message from Home View Controller: The current user is \(userEmail)")
        
    }
    
    
    @IBAction func didTapUpload(_ sender: UIButton) {
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
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

}

extension HomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //To be tested: let cell = UITableViewCell(style: .default, reuseIdentifier: "fileCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath)
        cell.textLabel?.text = "Cloud file..."
        return cell
    }

}

extension HomeViewController: UITableViewDelegate {
    
}
