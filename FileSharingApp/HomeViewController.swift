//
//  HomeScreenViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-08-28.
//
/// Description: A native iOS app that enables users to upload, download, delete, and share files using Firebase features (Firebase Authentication and Firebase Cloud Storage).

import UIKit
import FirebaseAuth
import FirebaseStorage

class HomeViewController: UIViewController {
    
    // Later, I can add a label in Home screen to show the email of the currently logged in user and set the text with the value of userEmail...
    
    
    @IBOutlet weak var homeTableView: UITableView!
    
    private let myStorageRef = Storage.storage().reference()
    
    var fileList: [StorageReference] = [] /// Array containing the names of the files stored in the cloud.
    // let folderList: [String] = [] /// Array containing the names of the folders stored in the cloud.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        homeTableView.dataSource = self
        homeTableView.delegate = self
        
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
        
        /// Getting the list of files available in the cloud
        myStorageRef.listAll { [self] result, error in
            if let unWrappedError = error {
                print("The error is \(unWrappedError)")
            }
            guard let myItems = result?.items else { // Array of file names
                return
            }
            
            guard let myPrefixes = result?.prefixes else { // Array of folder names
                return
            }
            
            fileList = myItems
//            for item in myItems {
//                fileList.append(item)
//            }
            /// Reloading the Home table view
            DispatchQueue.main.async {
                self.homeTableView.reloadData()
            }
        }
        
        // I need to implement the observe function here...
    }
    
    @IBAction func didTapUpload(_ sender: UIButton) {
        
        print("Number of files in the cloud: \(fileList.count)")
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
        return fileList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Expression to be tested: let cell = UITableViewCell(style: .default, reuseIdentifier: "fileCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath)
        
        cell.textLabel?.text = fileList[indexPath.row].name
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
        return cell
    }

}

extension HomeViewController: UITableViewDelegate {

}
