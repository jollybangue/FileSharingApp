//
//  HomeScreenViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-08-28.
//
// Description: A native iOS app that enables users to upload, download, delete, and share files using Firebase features (Firebase Authentication, Firebase Cloud Storage, and Firebase Realtime Database).

// Some important notes about iOS "Photos" and "Files" apps of the simulators
// 1- When we drag and drop files from the computer to the the "Photos" app gallery, the name of the file is changed. The app add a unique random key at the end of the original file name (E.g.: "File 1" in the computer becomes something like "File 1-6CEAC9E8-5385-4E51-B7F2-032128643381")
// 2- When we drag and drop files from the computer to the the "Files" app folder, the name of the file is unchanged.
// 3- We cannot edit the name of a file stored the "Photos" app galery
// 4- We can edit the name of a file stored the "Files" app folders
// 5- We can save a copy of a file stored the "Photos" app galery, in a folder of the app "Files". Obviously in that case, the copy saved in the "Files" folder can be renamed as much as we want.
// 6- We can import a photo saved in a "Files" folder in the "Photos" app gallery. In that case, the copy of the file saved in the "Photos" app gallery is automatically renamed with a format like this: "IMG_0003". The next saved file (in the "Photos" app gallery) will be "IMG_0004", ...

// 7- "preferredMIMEType" gives the type of the picked file, corresponding to the content type metadata of a file stored in Firebase Cloud Storage.

// TODO: Releasing version 1.0. Notes/Tasks: 1- Implement the remaining feature Upload from Files, 2- Publish on GitHub and remove irrelevant comments (TODOs, personnal notes, ...), also remove all Firebase accesses (by deleting "GoogleService-Info.plist" file?).

// TODO: Manage the Firebase security rules.

// TODO: "Upload from Gallery" action is OK. Now implement "Upload from Files" action...

// TODO: Implement the "Download in a selected folder" function.

// TODO: Improve the "Share file" function.

// TODO: Check if the error while connecting to the Firebase cloud storage is handled.

// TODO: Implement observers for all upload and download tasks.

// TODO: Manage upload and download duplications (to avoid uploading or downloading the same file many times.)

// TODO: Allow selecting many files in the table view. Allow deleting many selected files at the same time.

// TODO: Implement the "Rename file" functionality...

// TODO: Include folder management (see folder list, create a new folder, rename a folder, delete a folder, ...)

// TODO: Improve Alert/Toast management...

// TODO: Manage sorting files (by id, by name, by size, ...). By default, the files shown in the app are in the same order than the files in the cloud storage, and they sorted by increasing order (from small to higher, id1001, id1002, id1003, ...) of the ids in the realtime database. In that case, Firebase Firestore must be used instead of Realtime database.

// TODO: Try to delete all the files from the Home table view and see how it works.

// TODO: Unit tests.

// TODO: UI/UX tests.

// TODO: Refactoring.

// TODO: Generate app documentation.

import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class HomeViewController: UIViewController {
        
    @IBOutlet weak var homeTableView: UITableView!
    
    @IBOutlet weak var userEmailLabel: UILabel!
    
    /// Pointing to the Firebase Cloud Storage root folder. Android Kotlin equivalent: private val myStorageRef = Firebase.storage.reference
    private let myStorageRef = Storage.storage().reference()
    
    /// Root folder of the app data in the Firebase Cloud Storage.
    private let fileStorageRoot = "FileSharingApp"
    
    /// Pointing to the Firebase Realtime Database root node (It is the Realtime database reference). Android Kotlin: private val realtimeDbRef = Firebase.database.reference
    private let realtimeDbRef = Database.database().reference()
    
    /// Root folder of the app data in the Realtime database.
    private let realtimeDbRoot = "FileSharingApp"
        
    /// Array containing the realtime details of the files (key, name), details stored in the Firebase realtime database. realtimeFileList is used to feed the homeTableView.
    private var realtimeLocalFileList: [(String, String)] = []
    
    var listener: AuthStateDidChangeListenerHandle?
                
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        homeTableView.dataSource = self
        homeTableView.delegate = self
        
        /// Disable in the Navigation Controller the "Back to previous screen" button (located at the top left).
        navigationItem.setHidesBackButton(true, animated: false)
        
        navigationController?.navigationBar.prefersLargeTitles = false
        
        /// Adding a listener triggering a specific block of code (completion handler) depending if currentUser is nil or NOT.
        listener = Auth.auth().addStateDidChangeListener { [self] _, currentUser in
            
            guard let userEmail = currentUser?.email else {
                /// Case user is nil
                print("Message from Home View Controller: AUTHENTICATION ERROR, UNABLE TO GET THE CURRENT USER")

                AlertManager.showAlert(myTitle: "Authentication Error", myMessage: "Unable to get the current user.")
                return
            }
            
            /// Case user is NOT nil. Updating userEmailLabel.
            userEmailLabel.text = userEmail
            print("Message from Home View Controller: The current user is \(userEmail)")
        
        }
                
        copyDataFromStorageToRealtimeDB() // Getting the list of files available in the Firebase Cloud Storage and storing them in the Realtime Database.
        
        getAndObserveFileNamesFromRealtimeDB() // Get and observe the file list stored in the Realtime Database.
        
    }
    
    // Preparing segue for the next View Controllers.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the view controller ImageViewController using segue.destination.
        if let fileVC = segue.destination as? ImageViewController {
            
            // Pass the elements of the selected object (tuple (String, Storage reference)) to the new view controller ImageViewController.
            if let senderTuple = sender as? (String, StorageReference) {
                fileVC.selectedFileName = senderTuple.0
                fileVC.fileReference = senderTuple.1
            }
        }
        
        // Get the view controller WebViewController using segue.destination.
        if let webVC = segue.destination as? WebViewController {
            
            // Pass the elements of the selected object (tuple (String, Storage reference)) to the new view controller WebViewController.
            if let senderTuple = sender as? (String, StorageReference) {
                webVC.selectedFileName = senderTuple.0
                webVC.fileReference = senderTuple.1
            }
        }
    }
    
    /// This function gets the list of files stored in the Firebase cloud storage and save it into the Realtime database.
    private func copyDataFromStorageToRealtimeDB() {
        
        myStorageRef.child(fileStorageRoot).listAll { [self] result, error in
            
            if let unWrappedError = error {
                AlertManager.showAlert(myTitle: "Cloud Storage Error", myMessage: unWrappedError.localizedDescription)
                return
            }
            // guard let myPrefixes = result?.prefixes else {return} // Array of folder references
            guard let fileReferences = result?.items else {return} // Array of file references, files stored in the Firebase Cloud Storage.
            
            // TODO: Realtime Database resource management OPTIMIZATION - We need to COMPARE the Storage File List vs the Realtime File List. For now, comparing the number of elements in the Cloud Storage and the number of elements in the Realtime database is enough (assuming that the admin will never try to edit the filenames directly in the Realtime database terminal, also assuming that one random user will not delete a file while another random user is uploading another file at the same time...). Later I can add some code for checking the integrity of the Realtime database (check if any single value from the Cloud storage list matches with each unique value (file name) in the Realtime database. So number of element check + key/value check.
            
            // setting file names in Realtime Database.
            
            /// Getting the number of files in the Cloud Storage
            let numberOfilesInCloudStorage = fileReferences.count
            
            /// Getting the number of files currently registered in the Realtime Database.
            realtimeDbRef.child(realtimeDbRoot).getData { [self] error, snapshot in
                if let error {
                    AlertManager.showAlert(myTitle: "Realtime Database Error", myMessage: error.localizedDescription)
                    return
                }
                guard let numberOfFilesInRealtimeDB = snapshot?.childrenCount else { print("ERROR!!!");return}
                
                print("INITIALIZATION: Number of files in Firebase Cloud Storage: \(numberOfilesInCloudStorage)")
                print("INITIALIZATION: Number of files in Realtime Database: \(numberOfFilesInRealtimeDB)")
                                
                if numberOfFilesInRealtimeDB != numberOfilesInCloudStorage {
                    // Reinitialization and update of the Realtime Database.
                    print("numberOfilesInCloudStorage IS NOT equal to numberOfFilesInRealtimeDB. *** PROCESSING REALTIME DATABASE REINITIALIZATION AND UPDATE ***")
                    
                    realtimeDbRef.child(realtimeDbRoot).removeValue() // Deletes all the current values in realtime database app folder to avoid duplication issues.
                    
                    var id = 1001 // Initializing the file id which will be used to store the file in the Realtime database. With id = 11, we have ids from 11 to 99; With id = 101, we have ids from 101 to 999; With id = 1001, we have ids from 1001 to 9999.
                    for item in fileReferences {
                        // Writing file names gotten from Firebase cloud storage into Firebase Realtime database, with ids generated manually. Min: id1001, Max: id9999, Total: 8999 potential ids.
                        realtimeDbRef.child(realtimeDbRoot).child("id\(id)").setValue(item.name)
                        // Generating my own ids instead of using random ids generated by childByAutoId() will allow the Android version of this app to use the same Realtime database (since childbyAutoId() doesn't exist in Android Kotlin). I must implement the same id manager, with the same rules, in the Android app.
                        id += 1 // Incrementing the id.
                    }
                    
                } else {
                    print("numberOfilesInCloudStorage is equal to numberOfFilesInRealtimeDB. No need to reinitialize and update the Realtime Database...")
                }
            }
        } // END ListAll()
    } // END copyDataFromStorageToRealtimeDB()
    
    /// This function allows the app to get and observe in realtime, the name of the files stored in the Firebase cloud storage.
    private func getAndObserveFileNamesFromRealtimeDB() {
        
        realtimeDbRef.child(realtimeDbRoot).observe(.value) { [self] fileListSnapshot in
            
            guard let currentFileList = fileListSnapshot.value as? [String: String] else {return}
            
            realtimeLocalFileList.removeAll() // Delete all values stored in realtimeFileList to avoid duplication issues.
            // It is VERY IMPORTANT to sort elements inside the array currentFileList. Otherwise, the files will be shown randomly inside the tableview of the iOS app.
            let sortedFileList = currentFileList.sorted(by: <) // Sorting items from the smallest id to the highest id.
            
            for (key, item) in sortedFileList {
                realtimeLocalFileList.append((key, item))
            }
            homeTableView.reloadData() // Reloading homeTableView with the updated realtimeLocalFileList.
            
        } withCancel: { error in
            AlertManager.showAlert(myTitle: "Realtime Database Error", myMessage: error.localizedDescription)
            return
        }
    }
    
    /// This function deletes permanently from the Firebase Cloud Storage a file given its name.
    private func deleteFileFromCloudStorage(nameOfTheFile: String) {
        
        myStorageRef.child(fileStorageRoot).child(nameOfTheFile).delete { [self] error in
            
            if let fileDeletionError = error {
                AlertManager.showAlert(myTitle: "File Deletion Error", myMessage: "\"\(nameOfTheFile)\"\n\(fileDeletionError)")
                return
                
            } else {
                copyDataFromStorageToRealtimeDB() // Getting the list of files available in the Firebase Cloud Storage and storing them in the Realtime Database.
                // No need to call getAndObserveFileNamesFromRealtimeDB() because it needs to be called only once and it has already been called at the end of the viewDidLoad() function.
                AlertManager.showAlert(myTitle: "File deleted", myMessage: "The file \"\(nameOfTheFile)\" has been succesfully deleted from the cloud.")
            }
        }
    }
    
    /// This function uploads a file picked on the iPhone to the Firebase Cloud Storage.
    private func uploadFileToCloudStorage(fileNameWithExtension: String, fileData: Data, fileMetadata: StorageMetadata) {
        
        // Note: In the uploadFileToCloudStorage() function, putData should be used instead of putFile in Extensions. (Note that here, PHPickerViewControllerDelegate is implemented as EXTENSION of HomeViewController).
        // Because using putFile, the app tries to access the file located in the local URL, but unfortunately (probably for security reasons), the file is not reacheable in EXTENSIONS.
        // Note: putData() asynchronously uploads data to the currently specified StorageReference. This is not recommended for large files, and one should instead upload a file from disk.
        
        myStorageRef.child(fileStorageRoot).child(fileNameWithExtension).putData(fileData, metadata: fileMetadata) { [self] maybeMetadata, maybeError in
            
            if let uploadingError = maybeError {
                AlertManager.showAlert(myTitle: "File Upload Error", myMessage: uploadingError.localizedDescription)
                return
            }
            
            guard let uploadedFileMetadata = maybeMetadata else {return}
            
            // TODO: Implement an upload progress observer here... Using UIProgressView...
            
            // TODO: Add some code to avoid uploading duplicate files (check if the names, sizes and types of the files match...), or uploading the same file again and again.
            
            AlertManager.showAlert(myTitle: "File Uploaded", myMessage: "The file \"\(fileNameWithExtension)\" has been successfully uploaded in the Cloud Storage")
            
            copyDataFromStorageToRealtimeDB()
            // No need to call getAndObserveFileNamesFromRealtimeDB() because it needs to be called only once and it has already been called at the end of the viewDidLoad() function.
        }
    }
    
    @IBAction func didTapUpload(_ sender: UIButton) {
        
        /// Creating an alert for choosing between actions "Upload from Gallery" and "Upload from Files"
        let uploadFileAlert = UIAlertController(title: "Upload a File", message: "Please choose the location of your file", preferredStyle: .alert)
        
        /// Upload Action #1: Upload an image or a video located in phone gallery (app "Photos")
        let uploadFromGalleryAction = UIAlertAction(title: "Upload from Gallery", style: .default) { [self] _ in
            
            var mediaPickerConfig = PHPickerConfiguration()
            mediaPickerConfig.selectionLimit = 1  // TODO: Allow picking more than one file in the gallery for uploading...
                    
            /// Present a photo picker view controller that allows user to pick a media (photo or video)
            let mediaPickerVC = PHPickerViewController(configuration: mediaPickerConfig)
            
            mediaPickerVC.delegate = self
            
            present(mediaPickerVC, animated: true)
        }
        
        // TODO: Upload Action #2: Upload a file located anywhere else in the phone (any kind of file accessible through the app "Files").
        let uploadFromFilesAction = UIAlertAction(title: "Upload from Files", style: .default) { [self] _ in
            //let filePickerVC = UIDocumentPickerViewController(forExporting: .init())
            
            let localFilesURLs = FileManager.default.urls(for: .userDirectory, in: .userDomainMask)
            // TODO: Difference between ".userDirectory" and ".documentDirectory". Also look for "On My iPhone" specific URL...

            let filePickerVC = UIDocumentPickerViewController(forExporting: localFilesURLs, asCopy: true)
            present(filePickerVC, animated: true)
        }
        
        uploadFileAlert.addAction(uploadFromGalleryAction)
        uploadFileAlert.addAction(uploadFromFilesAction)
        uploadFileAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        
        present(uploadFileAlert, animated: true)

    }
    
    /// Signing out and back to LoginViewController
    @IBAction func didTapSignOut(_ sender: UIButton) {
        
        guard let userEmail = Auth.auth().currentUser?.email else {return} // Getting the current user email address.
        
        let confirmationAlert = UIAlertController(title: "Confirmation", message: "\(userEmail)\nDo you want to sign out?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { [self] _ in
            
            do {
                try Auth.auth().signOut() ///Signing out
                guard let unwrappedListener = listener else {return}
                Auth.auth().removeStateDidChangeListener(unwrappedListener) // Removing the listener: AuthStateDidChangeListenerHandle to avoid error message ("Unable to get the current user.") while signing out and moving to the Login Screen.
                performSegue(withIdentifier: "homeToLogin", sender: self) // Returning to Login Screen.
                
                /// Destroying the current view controller (HomeViewController). In that way, being in the new view controller (LoginViewController), it will not be possible to back to this view controller (HomeViewController).
                willMove(toParent: nil)
                view.removeFromSuperview()
                removeFromParent()
                
            } catch let signOutError as NSError {
                AlertManager.showAlert(myTitle: "Signing out failed", myMessage: signOutError.localizedDescription)
                return
            }
        }
        
        confirmationAlert.addAction(cancelAction)
        confirmationAlert.addAction(signOutAction)
        
        present(confirmationAlert, animated: true)
    }
}

extension HomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return realtimeLocalFileList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: Expression to be tested: let cell = UITableViewCell(style: .default, reuseIdentifier: "fileCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath)
        
        cell.textLabel?.text = realtimeLocalFileList[indexPath.row].1
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
        return cell
    }
}

extension HomeViewController: UITableViewDelegate {
    
    /// Actions taken when the user tap on a file in the homeTableView. When user tap on a file, an Alert showing the details (properties, metadata, ...) of the file and various selectable actions is triggered.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let nameOfTheFileSelectedInHomeTableView: String = realtimeLocalFileList[indexPath.row].1
        
        // And all the information needed by the application IS get from the Realtime Database.
        // It is better to proceed like that because is not possible to access informations like metadata or file list outside the Cloud Storage functions getMetadata(), listAll(), ...
        
        /// Getting metadata of a file stored in Firebase cloud storage based on the name of the same file in the local device. I tried to make a separate function to make the code more readable but it didn't work. The metadata are not available or accessible outside the Firebase native function below "getMetadata".
        myStorageRef.child(fileStorageRoot).child(nameOfTheFileSelectedInHomeTableView).getMetadata { [self] metadata, error in
            
            if let metadataError = error {
                AlertManager.showAlert(myTitle: "Metadata Error", myMessage: "\(metadataError)")
                return
            }
            /// Collecting properties of the selected file.
            guard let fileKind = metadata?.contentType,
                  let fileSize = metadata?.size.formatted(),
                  let fileTimeCreated = metadata?.timeCreated?.formatted(date: .abbreviated, time: .standard),
                  let filetimeModified = metadata?.updated?.formatted(date: .abbreviated, time: .standard),
                  let fileNameInCloudStorage = metadata?.name,
                  let fileContentType = metadata?.contentType
            else {
                AlertManager.showAlert(myTitle: "Metadata Error", myMessage: "Unable to get the file metadata.")
                return
            }
            
            /// Cloud Storage Reference of the selected file.
            let fileToOpenRef = myStorageRef.child(fileStorageRoot).child(fileNameInCloudStorage)
            
            let fileDetailsAlert = UIAlertController(title: nameOfTheFileSelectedInHomeTableView, message: "\nKind: \(fileKind) file\n" + "\nSize: \(fileSize) bytes\n" + "\nCreated: \(fileTimeCreated)\n" + "\nModified: \(filetimeModified)\n", preferredStyle: .alert)
            
            /// Action #1: Open image in ImageView
            let openImageAction = UIAlertAction(title: "Open in Image View", style: .default) { [self] _ in
                
                if (fileContentType != "image/jpeg") && (fileContentType != "image/png") {
                    AlertManager.showAlert(myTitle: "Error", myMessage: "The file you selected is not an image. Only image files can be loaded in Image View.")
                    return
                }
                // Open selected image in the ImageViewController
                self.performSegue(withIdentifier: "showImage", sender: (fileNameInCloudStorage, fileToOpenRef))
            }
            
            /// Action #2: Open file in WebKit View
            let openInWebKitViewAction = UIAlertAction(title: "Open in WebKit View", style: .default) { _ in
                self.performSegue(withIdentifier: "showWebView", sender: (fileNameInCloudStorage, fileToOpenRef))
            }
            
            // TODO: Action #3: Open file with default system resources
            let openFileAction = UIAlertAction(title: "Open with System", style: .default) { _ in
                // TODO: Open the selected file with the system default app...
            }
            
            /// Action #4: Download a file located in Firebase Cloud Storage and save it on local device. Download file in app default folder (folder: "FileSharingApp"). The downloaded files are opened by default with Safari.
            let downloadFileAction = UIAlertAction(title: "Download in the Default App Folder", style: .default) { [self] _ in
                // Download a selected file stored in the cloud and save that file in the local folder "FileSharingApp", which is accessible using the iOS app "Files".
                let fileToDownloadRef = myStorageRef.child(fileStorageRoot).child(nameOfTheFileSelectedInHomeTableView)
                                
                /// "localURLs" is an Array containing the url of the current user's Document directory. The "urls()" function searches the folders defined in the given parameters.
                let localURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                // In iOS, the user Document directory of this app has the same name as the app (in this case: "FileSharingApp").
                // To make that folder visible in iOS through the app "Files", I have added the parameters "Supports opening documents in place" and "Application supports iTunes file sharing" to the "Info.plist" file, and set both parameters to "YES".
                let appDocumentFolderURL = localURLs[0] // Get the url of the default local folder / "Document directory" of this app (named in Files app "FileSharingApp")
                
                /// Created "downloadFileTask" to monitor and manage the download process. The app writes the downloaded files at the local iPhone URL "appDocumentFolderURL" (pointing to the folder "FileSharingApp").
                let downloadFileTask = fileToDownloadRef.write(toFile: appDocumentFolderURL.appending(path: nameOfTheFileSelectedInHomeTableView)) { maybeURL, maybeError in
                    if let error = maybeError {
                        AlertManager.showAlert(myTitle: "Download Error", myMessage: error.localizedDescription)
                        return
                    }
                    
                    guard let downloadedFileLocalURL = maybeURL else {return}
                    AlertManager.showAlert(myTitle: "Download Complete", myMessage: "The file has been successfully downloaded and saved on local device.")
                    print("Downloaded file local URL: \(downloadedFileLocalURL)")
                }
                // TODO: Manage duplication. Add conditions to avoid downloading the same file locally many times(So avoid erasing existing file with the same name).
            }
            
            // TODO: Action #5: Choose where to save the downloaded file
            let downloadInSpecifiedLocationAction = UIAlertAction(title: "Download in Specified Location", style: .default) { _ in
                // TODO: Download the chosen file and select where to save that file in the local device.
                // TODO: Add "Open file location folder" action.
            }
            
            // TODO: Action #6: Generate a link to access the selected file stored in Firebase Cloud Storage. Interface to be improved...
            let shareFileAction = UIAlertAction(title: "Share", style: .default) { [self] _ in
                // Generate and download the link of the selected file and copy that link to the iPhone clipboard
                myStorageRef.child(fileStorageRoot).child(fileNameInCloudStorage).downloadURL { maybeUrl, maybeError in
                    if let error = maybeError {
                        AlertManager.showAlert(myTitle: "Share Error", myMessage: error.localizedDescription)
                        return
                    }
                    
                    guard let url = maybeUrl else {return}
                    UIPasteboard.general.url = url // Copying the downloaded URL into the iPhone clipboard.
                    print("File link to share: \(url)")
                }
                
                AlertManager.showAlert(myTitle: fileNameInCloudStorage, myMessage: "File link copied to clipboard.")
                
            }
            
            /// Action #7: Delete file
            let deleteFileMenuAction = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
                // Permanently delete from the Firebase Cloud Storage a selected file.
                let deleteConfirmationAlert = UIAlertController(title: "Delete File", message: "Do you want to permanently delete the file \(nameOfTheFileSelectedInHomeTableView) from the cloud?", preferredStyle: .alert)
                
                let deleFileAction = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
                    deleteFileFromCloudStorage(nameOfTheFile: nameOfTheFileSelectedInHomeTableView) /// Delete permanently the file named "fileToBeDeleted" from the Firebase Cloud Storage.
                    
                    // TODO: For future improvement, instead of permanently delete the files from the Firebase cloud storage, the files could just be moved to a trash or recycle bin.
                }
                
                deleteConfirmationAlert.addAction(deleFileAction)
                deleteConfirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                present(deleteConfirmationAlert, animated: true)
            }
            
            fileDetailsAlert.addAction(openImageAction)
            fileDetailsAlert.addAction(openInWebKitViewAction)
            fileDetailsAlert.addAction(openFileAction)
            fileDetailsAlert.addAction(downloadFileAction)
            fileDetailsAlert.addAction(downloadInSpecifiedLocationAction)
            fileDetailsAlert.addAction(shareFileAction)
            fileDetailsAlert.addAction(deleteFileMenuAction)
            fileDetailsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel)) /// Action #8: Cancel
            
            present(fileDetailsAlert, animated: true)
        } // END getMetadata()
    }
    
    /// Implementing a swipe action for deleting a selected file
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let nameOfTheFileToDelete: String = realtimeLocalFileList[indexPath.row].1 // Getting the name of the file to delete from the realtimeLocalFileList(which is used as datasource of homeTableView).
        
        let deleteConfirmationAlert = UIAlertController(title: "Delete File", message: "Do you want to permanently delete the file \(nameOfTheFileToDelete) from the cloud?", preferredStyle: .alert)
        
        let deleFileAction = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
            deleteFileFromCloudStorage(nameOfTheFile: nameOfTheFileToDelete) /// Delete permanently the file named "fileToBeDeleted" from the Firebase Cloud Storage.
        }
        
        deleteConfirmationAlert.addAction(deleFileAction)
        deleteConfirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        let deleteFileContextualAction = UIContextualAction(style: .destructive, title: "Delete") { [self] _, _, completion in
            present(deleteConfirmationAlert, animated: true)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteFileContextualAction])
    }
}

extension HomeViewController: PHPickerViewControllerDelegate {
    
    /// Photo picker view controller. As its name indicates, only photos and video can be picked from here. It triggers the Gallery/"Photos" app on iPhone.
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        // TODO: Allow picking (and then uploading) more than one file at the same time.
        
        guard let fileProvider = results.first?.itemProvider else {return} // Pickup the item provider of the first object of the array "results".
        
        // Getting the name (name WITHOUT extension) of the file the user picked, using ".suggestedName". We should use ".preferredFilenameExtension" to get the file extension.
        // To get the the whole name of the picked file including extension file, we shoud get the local URL of the picked file and then extract the last component of the URL using ".lastPathComponent"
        guard let pickedFileName = fileProvider.suggestedName else {return} // Name of the picked file WITHOUT extension.
        
        guard let pickedFileType = fileProvider.registeredContentTypes.first else {return}
        
        /// Name of the type (as represented in Firebase) of the local file selected (picked from the gallery (Photos app)). Can be passed as metadata parameter when uploading the file.
        guard let pickedFileContentTypeName = pickedFileType.preferredMIMEType else {return} // "preferredMIMEType" gives the name of the type of the picked file, corresponding to the "content type" metadata of a file stored in Firebase Cloud Storage.

        guard let pickedFileExtension = pickedFileType.preferredFilenameExtension else {return} // Extension of the local file picked. Can be used while uploading the file.
        
        let pickedFileTypeIdentifier = pickedFileType.identifier // iOS identifier of the type of the picked file. Example "public.jpeg". It is used for loading file representation (for example to get the local URL of the picked file).

        /// pickedFileMetadata contains the metadata of the file the user picked for uploading.
        let pickedFileMetadata = StorageMetadata()
        
        /// Setting the content type of the file to be uploaded. Otherwise, the file will be uploaded in Firebase Storage as "application/octet-stream" (so with no specific extension)...
        pickedFileMetadata.contentType = pickedFileContentTypeName // FORMAT (example): fileMetadata.contentType = "image/jpeg"
                
        // ***** Getting the (temporary) local URL of the picked file *****
        // loadInPlaceFileRepresentationForTypeIdentifier: is not supported. We use loadFileRepresentationForTypeIdentifier instead to be able to extract the local URL of the file selected for uploading.
        // The function loadFileRepresentation() below asynchronously writes a copy of the provided typed data to a temporary file, returning a progress object.
        fileProvider.loadFileRepresentation(forTypeIdentifier: pickedFileType.identifier) { [self] maybeURL, maybeError in
            
            if let gettingURLError = maybeError {
                AlertManager.showAlert(myTitle: "Upload Error", myMessage: gettingURLError.localizedDescription)
                return
            }
            /// "pickedLocalFileURL" contains the URL of the local file that the user picked/chose for uploading. In fact, when the file is picked, iOS write a copy of the file in a temporary folder and stores the local URL of that temp file in "pickedFileLocalURL". Again, probably for security purposes.
            guard let pickedLocalFileURL = maybeURL else {return}
            
            /// "pickedFileNameWithExtension" contains the complete name of the file picked by the user for uploading... It is extracted from the complete URL of the local (temp) file.
            let pickedFileNameWithExtension = pickedLocalFileURL.lastPathComponent
            
            // Loading in memory the file to be uploaded
            fileProvider.loadDataRepresentation(forTypeIdentifier: pickedFileType.identifier) { [self] maybeData, maybeError in
                if let uploadError = maybeError {
                    AlertManager.showAlert(myTitle: "Upload Error", myMessage: uploadError.localizedDescription)
                    return
                }
                /// pickedFileData contains the data of the file to be uploaded in the Firebase Cloud Storage.
                guard let pickedFileData = maybeData else {return}
                
                // Uploading the picked file using its local temporary URL
                uploadFileToCloudStorage(fileNameWithExtension: pickedFileNameWithExtension, fileData: pickedFileData, fileMetadata: pickedFileMetadata)
            
            } /// END of fileProvider.loadDataRepresentation()
        
        } /// END of fileProvider.loadFileRepresentation()
        
        picker.dismiss(animated: true)
    }
}
