//
//  HomeScreenViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-08-28.
//
// Description: A native iOS app that enables users to upload, download, delete, and share files using Firebase features (Firebase Authentication and Firebase Cloud Storage).

// Some important notes about iOS "Photos" and "Files" apps of the simulators
// 1- When we drag and drop files from the computer to the the "Photos" app gallery, the name of the file is changed. The app add a unique random key at the end of the original file name (E.g.: "File 1" in the computer becomes something like "File 1-6CEAC9E8-5385-4E51-B7F2-032128643381")
// 2- When we drag and drop files from the computer to the the "Files" app folder, the name of the file is unchanged.
// 3- We cannot edit the name of a file stored the "Photos" app galery
// 4- We can edit the name of a file stored the "Files" app folders
// 5- We can save a copy of a file stored the "Photos" app galery, in a folder of the app "Files". Obviously in that case, the copy saved in the "Files" folder can be renamed as much as we want.
// 6- We can import a photo saved in a "Files" folder in the "Photos" app gallery. In that case, the copy of the file saved in the "Photos" app gallery is automatically renamed with a format like this: "IMG_0003". The next saved file (in the "Photos" app gallery) will be "IMG_0004", ...

import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class HomeViewController: UIViewController {
    
    // TODO: Later, I can add a label in Home screen to show the email of the currently logged in user and set the text with the value of userEmail...
    
    @IBOutlet weak var homeTableView: UITableView!
    
    private let myStorageRef = Storage.storage().reference()    /// Firebase Cloud Storage refence
    private let fileStorageRoot = "FileSharingApp" /// Root of the project data in the Firebase Cloud Storage
    
    private let realtimeDbRef = Database.database().reference() /// Realtime database reference
    private let realtimeDbRoot = "FileSharingApp" /// Root of the project data in the Realtime database
    
    // USELESS: private var fileList: [StorageReference] = [] // Array containing the references (names, paths, links) of the files stored in the Firebase cloud storage.
    // var folderList: [StorageReference] = [] /// Array containing the references (names, paths, links) of the folders stored in the cloud.
    
    /// Array containing the realtime details of the files (key, name), details stored in the Firebase realtime database...
    private var realtimeFileList: [(String, String)] = []
            
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
    
    
    /// This function get the list of files stored in the Firebase cloud storage and save it into the Realtime database using the setFileNamesInRealtimeDB() function.
    private func copyDataFromStorageToRealtimeDB() {
        myStorageRef.child(fileStorageRoot).listAll { [self] result, error in
            if let unWrappedError = error {
                print("The error is \(unWrappedError)")
            }
            // guard let myPrefixes = result?.prefixes else {return} // Array of folder references
            guard let fileReferences = result?.items else {return} // Array of file references
            setFileNamesInRealtimeDB(myFileList: fileReferences)
        }
        // fileList is EMPTY here (outside the listAll function)
    }
    
    /// This function cannot be directly called by the app, but ONLY by the function copyDataFromStorageToRealtimeDB() and can be ONLY used INSIDE the "listAll" function.
    private func setFileNamesInRealtimeDB(myFileList: [StorageReference]) {
        realtimeDbRef.child(realtimeDbRoot).removeValue() ///Deletes all the current values in realtime database to avoid duplication issues.
        for item in myFileList {
            ///childbyAutoId() generates a random unique key associated with each file name.
            realtimeDbRef.child(realtimeDbRoot).childByAutoId().setValue(item.name)
        }
    }
    
    /// This function allows the app to get and observe in realtime, the name of the files stored in the Firebase cloud storage.
    private func getFileNamesFromRealtimeDB() {
        realtimeDbRef.child(realtimeDbRoot).observe(.value) { [self] fileListSnapshot in
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
    
    /// This function delete permanently from the Firebase Cloud Storage a file given its name.
    private func deleteFileFromCloudStorage(nameOfTheFile: String) {
        myStorageRef.child(fileStorageRoot).child(nameOfTheFile).delete { [self] error in
            if let fileDeletionError = error {
                AlertManager.showAlert(myTitle: "File deletion error", myMessage: "Something went wrong while deleting the file \"\(nameOfTheFile)\".\nError: \(fileDeletionError)")
            } else {
                copyDataFromStorageToRealtimeDB() ///Getting the list of files available in the Firebase Cloud Storage and storing them in the realtime database.
                getFileNamesFromRealtimeDB()
                AlertManager.showAlert(myTitle: "File deleted", myMessage: "The file \"\(nameOfTheFile)\" has been succesfully deleted from the cloud.")
            }
        }
    }
    
    
    ///This function upload a file picked on the phone to the Firebase Cloud Storage
    private func uploadFile(file: UIImage, fileName: String) {
        guard let fileInJpeg = file.jpegData(compressionQuality: 1.0) else {
            print("##### Error while converting the chosen file to JPEG.")
            return
        }
        
        /// A file metadata containing information about the content type, otherwise, the file will be uploaded as application/octet-stream (no specific extension)
        let fileMetadata = StorageMetadata()
        fileMetadata.contentType = "image/jpeg"
        
        myStorageRef.child(fileStorageRoot).child("\(fileName).jpg").putData(fileInJpeg, metadata: fileMetadata) { [self] metadata, error in
            if let uploadError = error {
                print("##### Failed to upload the file. Error: \(uploadError.localizedDescription)")
                return
            }
            guard let uploadedFilename = metadata?.name else {
                print("##### Error while getting the name of the uploaded file.")
                return
            }
            
            // TODO: I need to implement an upload progress observer here...
            
            // TODO: I should add some code to avoid uploading duplicate files (check if the names, sizes and types of the files match...), or uploading the same file again and again.
            
            AlertManager.showAlert(myTitle: "File uploaded", myMessage: "The file \"\(uploadedFilename)\" has been successfully uploaded in the cloud.")
            
            print("### Name of the picked local file (fileName): \(fileName)")
            print("### Name of the file stored in the cloud (uploadedFilename): \(uploadedFilename)")
            
            copyDataFromStorageToRealtimeDB()
            
            getFileNamesFromRealtimeDB()
            
        }
    }
    
    
    @IBAction func didTapUpload(_ sender: UIButton) {
        
        var mediaPickerConfig = PHPickerConfiguration()
        mediaPickerConfig.selectionLimit = 1
                
        /// Present a photo picker view controller that allows user to pick a media (photo or video)
        let mediaPickerVC = PHPickerViewController(configuration: mediaPickerConfig)
        
        // TODO: In the future, the app should be able to upload any kind of file (NOT only photos and videos)
        // Creating an alert for choosing between actions "Media (Photos or Videos)" and "Other files"
        //let filePickerVC = UIDocumentPickerViewController(forExporting: .init())
        
        mediaPickerVC.delegate = self
        
        present(mediaPickerVC, animated: true)
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
        
        let fileSelectedInHomeTableView: String = realtimeFileList[indexPath.row].1
        
        // TODO: In the future, for optimization, I should implement one function to get all the metadata (including the list of files) from Firebase cloud storage and save them in the Realtime database.
        /// And all the information needed by the application should be get from the Realtime database.
        /// It is better to proceed like that because is not possible to access informations like metadata or file list outside the Cloud Storage functions getMetadata and listAll.
        
        myStorageRef.child(fileStorageRoot).child(fileSelectedInHomeTableView).getMetadata { [self] metadata, error in
            if let myError = error {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Something went wrong with metadata. Error \(myError)")
            }
            guard let fileKind = metadata?.contentType,
                  let fileSize = metadata?.size.formatted(),
                  let fileTimeCreated = metadata?.timeCreated?.formatted(date: .abbreviated, time: .standard),
                  let filetimeModified = metadata?.updated?.formatted(date: .abbreviated, time: .standard),
                  let fileName = metadata?.name
            else {return}
            let fileDetailsAlert = UIAlertController(title: fileSelectedInHomeTableView, message: "\nKind: \(fileKind) file\n" + "\nSize: \(fileSize) bytes\n" + "\nCreated: \(fileTimeCreated)\n" + "\nModified: \(filetimeModified)\n", preferredStyle: .alert)
            
            let openFileAction = UIAlertAction(title: "Open", style: .default) { _ in
            }
            
            let downloadFileAction = UIAlertAction(title: "Download", style: .default) { _ in
            }
            
            let shareFileAction = UIAlertAction(title: "Share", style: .default) { _ in
                AlertManager.showAlert(myTitle: fileName, myMessage: "File link copied to clipboard.")
            }
            
            let deleteFileAction = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
                
                let deleteConfirmationAlert = UIAlertController(title: "Delete File", message: "Do you want to permanently delete the file \(fileSelectedInHomeTableView) from the cloud?", preferredStyle: .alert)
                
                let deleFileAction = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
                    deleteFileFromCloudStorage(nameOfTheFile: fileSelectedInHomeTableView) /// Delete permanently the file named "fileToBeDeleted" from the Firebase Cloud Storage.
                    
                    // TODO: For future improvement, instead of permanently delete the files from the Firebase cloud storage, the files should just be moved to a trash or recycle bin.
                }
                
                deleteConfirmationAlert.addAction(deleFileAction)
                deleteConfirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                present(deleteConfirmationAlert, animated: true)
            }
                        
            fileDetailsAlert.addAction(openFileAction)
            fileDetailsAlert.addAction(downloadFileAction)
            fileDetailsAlert.addAction(shareFileAction)
            fileDetailsAlert.addAction(deleteFileAction)
            fileDetailsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(fileDetailsAlert, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let fileToBeDeleted: String = realtimeFileList[indexPath.row].1
        
        let deleteConfirmationAlert = UIAlertController(title: "Delete File", message: "Do you want to permanently delete the file \(fileToBeDeleted) from the cloud?", preferredStyle: .alert)
        
        let deleFileAction = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
            deleteFileFromCloudStorage(nameOfTheFile: fileToBeDeleted) /// Delete permanently the file named "fileToBeDeleted" from the Firebase Cloud Storage.
            
            // TODO: For future improvement, instead of permanently delete the files from the Firebase cloud storage, the files should just be moved to a trash or recycle bin.
        }
        
        deleteConfirmationAlert.addAction(deleFileAction)
        deleteConfirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        let deleteFileContextualAction = UIContextualAction(style: .destructive, title: "Delete") { [self] action, view, completion in
            present(deleteConfirmationAlert, animated: true)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteFileContextualAction])
    }
}

extension HomeViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        guard let fileProvider = results.first?.itemProvider else {return} // Pickup just the first object.
        // fileProvider.canLoadObject(ofClass: UIImage.self) This line seems to be useless...
        /// Instead of UIImage, try UTType or UTTypeMovie for videos
        /// NS stands for NeXTSTEP
        
        /// The name of file the user picked
        guard let pickedFileName = results.first?.itemProvider.suggestedName else {
            print("##### Error: Unable to get the name of the picked file...")
            return
        }
        
        ///Here we load ONLY the first object
        fileProvider.loadObject(ofClass: UIImage.self) { [self] wrappedFile, error in
            
            if let fileError = error {
                print("##### Error while loading the file. It seems that the picked file is not an image/photo. Error: \(fileError.localizedDescription)")
                return
            }
            
            guard let pickedFile = wrappedFile as? UIImage else {
                print("##### Error: Failed to cast the file as UIImage.")
                return
            }
            
            DispatchQueue.main.sync {
                uploadFile(file: pickedFile, fileName: pickedFileName)
            }
        }
        
        picker.dismiss(animated: true)
    }
}

