//
//  HomeScreenViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-08-28.
//
// Description: A native iOS app that enables users to upload, download, delete, and share files using Firebase features (Firebase Authentication and Firebase Cloud Storage).

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class HomeViewController: UIViewController {
    
    // Later, I can add a label in Home screen to show the email of the currently logged in user and set the text with the value of userEmail...
    
    @IBOutlet weak var homeTableView: UITableView!
    
    private let myStorageRef = Storage.storage().reference()
    private let realtimeDBRef = Database.database().reference()
    private let parentNode = "Files"
    
    // USELESS: private var fileList: [StorageReference] = [] // Array containing the references (names, paths, links) of the files stored in the Firebase cloud storage.
    // var folderList: [StorageReference] = [] /// Array containing the references (names, paths, links) of the folders stored in the cloud.
    private var realtimeFileList: [(String, String)] = [] // Array containing the realtime details of the files (key, name), details stored in the realtime database...
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        homeTableView.dataSource = self
        homeTableView.delegate = self
        
        // Disable in the Navigation Controller the "Back to previous screen" button (located at the top left)
        navigationItem.setHidesBackButton(true, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // I prefer NOT to show alerts here because it will also imply the management of if conditions
        // The alerts are directly triggered from Register or Login view controllers.
        
        guard let userEmail = Auth.auth().currentUser?.email else {return}
        print("Message from Home View Controller: The current user is \(userEmail)")
        
        copyDataFromStorageToRealtimeDB() ///Getting the list of files available in the Firebase Cloud Storage and storing them in the realtime database.
        getFileNamesFromRealtimeDB()
    }
    
    private func copyDataFromStorageToRealtimeDB() {
        myStorageRef.listAll { [self] result, error in
            if let unWrappedError = error {
                print("The error is \(unWrappedError)")
            }
            // guard let myPrefixes = result?.prefixes else {return} // Array of folder references
            guard let fileReferences = result?.items else {return} // Array of file references
            setFileNamesInRealtimeDB(myFileList: fileReferences)
            //fileList = fileReferences ///This line is useless. It is here just for debugging purposes.
        }
        // fileList is EMPTY here (outside the listAll function)
    }
    
    private func setFileNamesInRealtimeDB(myFileList: [StorageReference]) {
        realtimeDBRef.child(parentNode).removeValue() ///Deletes all the current values in realtime database to avoid duplication issues.
        for item in myFileList {
            ///childbyAutoId() generates a random unique key associated with each file name.
            realtimeDBRef.child(parentNode).childByAutoId().setValue(item.name)
        }
    }
    
    private func getFileNamesFromRealtimeDB() {
        realtimeDBRef.child(parentNode).observe(.value) { [self] fileListSnapshot in
            guard let currentFileList = fileListSnapshot.value as? [String: String] else {return}
            realtimeFileList.removeAll() ///Deletes all values stored in realtimeFileList to avoid duplication issues.
            let sortedFileList = currentFileList.sorted{$0.0 < $1.0} ///Sorts by order the items stored in the currentFileList dictionnary and put them into sortedFileList
            for (key, item) in sortedFileList {
                realtimeFileList.append((key, item))
            }
            homeTableView.reloadData()
        }
        // realtimeFileList is EMPTY here (outside the observe() function)
    }

    
    @IBAction func didTapUpload(_ sender: UIButton) {
        //print("BUTTON PRESSED - Content of realtimeFileList: \(realtimeFileList)")
        //print("BUTTON PRESSED - Content of FileList: \(fileList)")
        //"realtimeFileList" and "fileList" variables are not empty when we press the button.
        //print("BUTTON PRESSED - Content of fileMetadata: \(fileMetadata)")

    }
    
    @IBAction func didTapSignOut(_ sender: UIButton) {
        
        let confirmationAlert = UIAlertController(title: "Confirmation", message: "Do you want to sign out?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            do {
                try Auth.auth().signOut() ///Signing out
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
        return realtimeFileList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        ///Expression to be tested: let cell = UITableViewCell(style: .default, reuseIdentifier: "fileCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath)
        
        cell.textLabel?.text = realtimeFileList[indexPath.row].1
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
        return cell
    }
}

extension HomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let fileRef = myStorageRef.child(realtimeFileList[indexPath.row].1)
        
        fileRef.getMetadata { [self] metadata, error in
            if let myError = error {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Something went wrong with metadata. Error \(myError)")
            }
            guard let fileKind = metadata?.contentType,
                  let fileSize = metadata?.size.formatted(),
                  let fileTimeCreated = metadata?.timeCreated?.formatted(date: .abbreviated, time: .standard),
                  let filetimeModified = metadata?.updated?.formatted(date: .abbreviated, time: .standard),
                  let fileName = metadata?.name
            else {return}
            let fileDetailsAlert = UIAlertController(title: realtimeFileList[indexPath.row].1, message: "\nKind: \(fileKind) file\n" + "\nSize: \(fileSize) bytes\n" + "\nCreated: \(fileTimeCreated)\n" + "\nModified: \(filetimeModified)\n", preferredStyle: .alert)
            
            let openFileAction = UIAlertAction(title: "Open", style: .default) { _ in
            }
            
            let downloadFileAction = UIAlertAction(title: "Download", style: .default) { _ in
            }
            
            let shareFileAction = UIAlertAction(title: "Share", style: .default) { _ in
                AlertManager.showAlert(myTitle: fileName, myMessage: "File link copied to clipboard")
            }
            
            let deleteFileAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                
            }
            
            let cancelFileAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            fileDetailsAlert.addAction(openFileAction)
            fileDetailsAlert.addAction(downloadFileAction)
            fileDetailsAlert.addAction(shareFileAction)
            fileDetailsAlert.addAction(deleteFileAction)
            fileDetailsAlert.addAction(cancelFileAction)
            
            present(fileDetailsAlert, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteFileContextualAction = UIContextualAction(style: .destructive, title: "Delete") { _,_,_ in
            
        }
        
        let deleteFileConfiguration = UISwipeActionsConfiguration(actions: [deleteFileContextualAction])
        
        
        
        return deleteFileConfiguration
    }
}
