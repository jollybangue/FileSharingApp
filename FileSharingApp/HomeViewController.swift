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

// TODO: Add a button to access the folder of the downloaded files. (The files downloaded by this app, from Firebase cloud storage.)

// TODO: Change printed messages to alert message for a better user experience (UX)... Used the Firebase predefined error messages.

// TODO: Improve the "Upload" function, allowing the app to upload any kind of file (not only images). See uploadFileInCloudStorage() function.

// TODO: Implement the "Download in a selected folder" function.

// TODO: Improve the "Share file" function.

// TODO: Implement observers for all upload and download tasks.

// TODO: Manage upload and download duplications (to avoid uploading or downloading the same file many times.)

// TODO: Allow selecting many files in the table view. Allow deleting many selected files at the same time.

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
        userEmailLabel.text = userEmail
        print("Message from Home View Controller: The current user is \(userEmail)")
        
        copyDataFromStorageToRealtimeDB() ///Getting the list of files available in the Firebase Cloud Storage and storing them in the realtime database.
        
        getFileNamesFromRealtimeDB()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the view controller ImageViewController using segue.destination.
        if let fileVC = segue.destination as? ImageViewController {
            
            // Pass the elements of the selected object (tuple (String, Storage reference)) to the new view controller ImageViewController.
            if let senderTuple = sender as? (String, StorageReference) {
                fileVC.selectedFileName = senderTuple.0
                fileVC.fileReference = senderTuple.1
            }
        }
        
        // Pass the elements of the selected object (tuple (String, Storage reference)) to the new view controller WebViewController.
        if let webVC = segue.destination as? WebViewController {
            
            // Pass the selected object to the new view controller.
            if let senderTuple = sender as? (String, StorageReference) {
                webVC.selectedFileName = senderTuple.0
                webVC.fileReference = senderTuple.1
            }
        }
    }
    
    /// This function get the list of files stored in the Firebase cloud storage and save it into the Realtime database using the setFileNamesInRealtimeDB() function.
    private func copyDataFromStorageToRealtimeDB() {
        myStorageRef.child(fileStorageRoot).listAll { [self] result, error in
            if let unWrappedError = error {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Error while fetching the list of elements stored in Firebase Cloud Storage.")
                print("Error details: \(unWrappedError)")
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
    
    /// This function uploads a file picked on the phone to the Firebase Cloud Storage
    private func uploadFileInCloudStorage(fileData: UTType, fileName: String) {
        // TODO: P0
        
    }
    
    /// This function uploads an image picked on the phone to the Firebase Cloud Storage
    private func uploadImageInCloudStorage(uIImageFile: UIImage, fileName: String) {
        
        guard let fileInJpeg = uIImageFile.jpegData(compressionQuality: 1.0) else {
            AlertManager.showAlert(myTitle: "Error", myMessage: "Error while converting the chosen file to JPEG")
            print("##### Error while converting the chosen file to JPEG.")
            return
        }
        
        /// A file metadata containing information about the content type, otherwise, the file will be uploaded in Firebase Storage as "application/octet-stream" (no specific extension)
        let fileMetadata = StorageMetadata()
        fileMetadata.contentType = "image/jpeg"
        
        myStorageRef.child(fileStorageRoot).child("\(fileName).jpeg").putData(fileInJpeg, metadata: fileMetadata) { [self] metadata, error in
            if let uploadError = error {
                AlertManager.showAlert(myTitle: "Uploading Error", myMessage: "Failed to upload the file")
                print("##### Failed to upload the file. Error: \(uploadError.localizedDescription)")
                return
            }
            guard let uploadedImageName = metadata?.name else {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Error while getting the name of the uploaded file.")
                print("##### Error while getting the name of the uploaded file.")
                return
            }
            
            // TODO: Implement an upload progress observer here... Using UIProgressView...
            
            // TODO: Add some code to avoid uploading duplicate files (check if the names, sizes and types of the files match...), or uploading the same file again and again.
            
            AlertManager.showAlert(myTitle: "File uploaded", myMessage: "The file \"\(uploadedImageName)\" has been successfully uploaded in the cloud.")
            
            print("### Name of the picked local file (fileName): \(fileName)")
            print("### Name of the file stored in the cloud (uploadedFilename): \(uploadedImageName)")
            
            copyDataFromStorageToRealtimeDB()
            
            getFileNamesFromRealtimeDB()
            
        }
    }
    
    
    @IBAction func didTapUpload(_ sender: UIButton) {
        
        let uploadFileAlert = UIAlertController(title: "Upload a file", message: "Please choose the location of your file", preferredStyle: .alert)
        
        /// Upload Action #1: Upload an image or a video located in phone gallery (app "Photos")
        let uploadFromGalleryAction = UIAlertAction(title: "Upload from Gallery", style: .default) { [self] _ in
            
            var mediaPickerConfig = PHPickerConfiguration()
            mediaPickerConfig.selectionLimit = 1
                    
            /// Present a photo picker view controller that allows user to pick a media (photo or video)
            let mediaPickerVC = PHPickerViewController(configuration: mediaPickerConfig)
            
            mediaPickerVC.delegate = self
            
            present(mediaPickerVC, animated: true)
        }
        
        /// Upload Action #2: Upload a file located in the local app folder named "FileSharingApp"
        let uploadFromFilesAction = UIAlertAction(title: "Upload from Files", style: .default) { _ in
            // TODO: In the future, the app should be able to upload any kind of file (NOT only photos and videos)
            // Creating an alert for choosing between actions "Media (Photos or Videos)" and "Other files"
            //let filePickerVC = UIDocumentPickerViewController(forExporting: .init())
        }
        
        uploadFileAlert.addAction(uploadFromGalleryAction)
        uploadFileAlert.addAction(uploadFromFilesAction)
        uploadFileAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        
        present(uploadFileAlert, animated: true)

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
    
    /// Actions taken when the user tap on a file
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let nameOfTheFileSelectedInHomeTableView: String = realtimeFileList[indexPath.row].1
        
        /// And all the information needed by the application should be get from the Realtime database.
        /// It is better to proceed like that because is not possible to access informations like metadata or file list outside the Cloud Storage functions getMetadata and listAll.
        
        /// Getting metadata of a file stored in Firebase cloud storage based on the name of the same file in the local device. I tried to make a separate function to make the code more readable but it didn't work. The metadata are not available or accessible outside the Firebase native function below "getMetadata".
        myStorageRef.child(fileStorageRoot).child(nameOfTheFileSelectedInHomeTableView).getMetadata { [self] metadata, error in
            
            if let myError = error {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Something went wrong with metadata. Error \(myError)")
            }
            
            guard let fileKind = metadata?.contentType,
                  let fileSize = metadata?.size.formatted(),
                  let fileTimeCreated = metadata?.timeCreated?.formatted(date: .abbreviated, time: .standard),
                  let filetimeModified = metadata?.updated?.formatted(date: .abbreviated, time: .standard),
                  let uploadedFileName = metadata?.name,
                  let fileContentType = metadata?.contentType
            else {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Unable to get the file metadata.")
                return
            }
            
            let fileToOpenRef = myStorageRef.child(fileStorageRoot).child(uploadedFileName)
            
            let fileDetailsAlert = UIAlertController(title: nameOfTheFileSelectedInHomeTableView, message: "\nKind: \(fileKind) file\n" + "\nSize: \(fileSize) bytes\n" + "\nCreated: \(fileTimeCreated)\n" + "\nModified: \(filetimeModified)\n", preferredStyle: .alert)
            
            
            /// Action #1: Open image in ImageView
            let openImageAction = UIAlertAction(title: "Open in Image View", style: .default) { [self] _ in
                
                if (fileContentType != "image/jpeg") && (fileContentType != "image/png") {
                    AlertManager.showAlert(myTitle: "Error", myMessage: "The file you selected is not an image. Only image files can be loaded in Image View.")
                    return
                }
                
                // Perform segue "showImage". TODO: In the future, instead of showing the downloaded imgage in an image view, I should also try a Web View or a WebKit View. So I will be able to open image files and many other files like PDFs, ...
                self.performSegue(withIdentifier: "showImage", sender: (uploadedFileName, fileToOpenRef))
            }
            
            /// Action #2: Open file in WebKit View
            let openInWebKitViewAction = UIAlertAction(title: "Open in WebKit View", style: .default) { _ in
                self.performSegue(withIdentifier: "showWebView", sender: (uploadedFileName, fileToOpenRef))
            }
            
            // TODO: Action #3: Open file with default system resources
            let openFileAction = UIAlertAction(title: "Open with System", style: .default) { _ in
                // TODO: Open the selected file with the system default app...
            }
            
            /// Action #4: Download a file located in Firebase Cloud Storage and save it on local device. Download file in app default folder (folder: "FileSharingApp"). The downloaded files are opened by default with Safari.
            let downloadFileAction = UIAlertAction(title: "Download in the default app folder", style: .default) { [self] _ in
                // Download a selected file stored in the cloud and save that file in the local folder "FileSharingApp"
                let fileToDownloadRef = myStorageRef.child(fileStorageRoot).child(nameOfTheFileSelectedInHomeTableView)
                                
                /// "localURLs" is an Array containing the url of the current user's Document directory. The "urls()" function searches the folders defined in the given parameters.
                let localURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                //let galleryURLs = FileManager.default.urls(for: ., in: <#T##FileManager.SearchPathDomainMask#>)
                
                /// In iOS, the user Document directory of this app has the same name as the app (in this case: "FileSharingApp").
                /// To make that folder visible in iOS through the app "Files", I have added the parameters "Supports opening documents in place" and "Application supports iTunes file sharing" to the "Info.plist" file, and set both parameters to "YES".
                let appDocumentFolderURL = localURLs[0] /// Get the url of the default local folder of this app ("FileSharingApp")
                
                /// Created "downloadFileTask" to monitor and manage the download process. The app writes the downloaded files in the "appDocumentFolderURL" ()
                let downloadFileTask = fileToDownloadRef.write(toFile: appDocumentFolderURL.appending(path: nameOfTheFileSelectedInHomeTableView)) { maybeURL, maybeError in
                    if let error = maybeError {
                        AlertManager.showAlert(myTitle: "Download Error", myMessage: "Unable to download and save the file on local device.")
                        print("Download error details: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let savedFileURL = maybeURL else {return}
                    AlertManager.showAlert(myTitle: "Download complete", myMessage: "The file has been successfully downloaded and saved on local device.")
                    print("Downloaded file local URL: \(savedFileURL)")
                }
                // TODO: Manage duplication. Add conditions to avoid downloading the same file locally many times(So avoid erasing existing file with the same name).
            }
            
            // TODO: Action #5: Choose where to save the downloaded file
            let downloadInSpecifiedLocationAction = UIAlertAction(title: "Download in specified location", style: .default) { _ in
                // TODO: Download the chosen file and select where to save that file in the local device.
                // TODO: Add "Open file location folder" action.
            }
            
            // TODO: Action #6: Generate a link to access the selected file stored in Firebase Cloud Storage. Interface to be improved...
            let shareFileAction = UIAlertAction(title: "Share", style: .default) { [self] _ in
                // Generate and download the link of the selected file and copy that link to the iPhone clipboard
                
                myStorageRef.child(fileStorageRoot).child(uploadedFileName).downloadURL { maybeUrl, maybeError in
                    if let error = maybeError {
                        AlertManager.showAlert(myTitle: "Download Error", myMessage: "Unable to get the URL of the selected file.")
                        print("##### Error details: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let url = maybeUrl else {
                        AlertManager.showAlert(myTitle: "Error", myMessage: "Something went wrong while unwrapping the URL.")
                        print("##### Error while unwrapping the URL.")
                        return
                    }
                    UIPasteboard.general.url = url // Copying the downloaded URL into the iPhone clipboard.
                    print("File link to share: \(url)")
                }
                
                AlertManager.showAlert(myTitle: uploadedFileName, myMessage: "File link copied to clipboard.")
                
            }
            
            /// Action #7: Delete file
            let deleteFileAction = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
                // Permanently delete from the Firebase Cloud Storage a selected file.
                let deleteConfirmationAlert = UIAlertController(title: "Delete File", message: "Do you want to permanently delete the file \(nameOfTheFileSelectedInHomeTableView) from the cloud?", preferredStyle: .alert)
                
                let deleFileAction = UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
                    deleteFileFromCloudStorage(nameOfTheFile: nameOfTheFileSelectedInHomeTableView) /// Delete permanently the file named "fileToBeDeleted" from the Firebase Cloud Storage.
                    
                    // TODO: For future improvement, instead of permanently delete the files from the Firebase cloud storage, the files should just be moved to a trash or recycle bin.
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
            fileDetailsAlert.addAction(deleteFileAction)
            fileDetailsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel)) /// Action #8: Cancel
            
            present(fileDetailsAlert, animated: true)
        }
    }
    
    /// Implementing a swipe action for deleting a selected file
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
    
    /// Photo picker view controller. As its name indicates, only photos and video can be picked from here. It triggers the Gallery/"Photos" app on iPhone.
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        // TODO: Allow picking (and then uploading) more than one file at the same time.
        
        guard let fileProvider = results.first?.itemProvider else {return} // Pickup the item provider of the first object of the array "results".
        //fileProvider.canLoadObject(ofClass: UIImage.self) // This line seems to be useless...
        /// Instead of UIImage, try UTType or UTTypeMovie for videos
        /// NS stands for NeXTSTEP
        
        /// Getting the name (name WITHOUT extension) of the file the user picked. We should use ".preferredFilenameExtension" to get the file extension.
        /// To get the the whole name of the picked file including extension file, we shoud get the local URL of the picked file and then extract the last component of the URL using ".lastPathComponent"
        guard let pickedFileName = fileProvider.suggestedName else {
            AlertManager.showAlert(myTitle: "Error", myMessage: "Unable to get the name of the picked file.")
            print("##### Error: Unable to get the name of the picked file...")
            return
        }
        
        guard let pickedFileType = fileProvider.registeredContentTypes.first else {return}
                
        guard let pickedFileContentTypeName = pickedFileType.preferredMIMEType else {return}
        
        guard let pickedFileExtension = pickedFileType.preferredFilenameExtension else {return}
        
        let pickedFileTypeIdentifier = pickedFileType.identifier
        
        let pickedFileMetadata = StorageMetadata()
        pickedFileMetadata.contentType = pickedFileContentTypeName
        //fileMetadata.contentType = "image/jpeg"
        
        /// Print the name of the picked file
        print("Name of the picked file: \(pickedFileName)")
        
        /// Name of the type (as represented in Firebase) of the local file selected (picked from the gallery (Photos app)). Can be passed as metadata parameter when uploading the file.
        print("***** Name of the type of the selected file (pickedFileType.preferredMIMEType) AKA Content type name: \(pickedFileContentTypeName)")
        
        /// Extension of the local file picked. Can be used while uploading the file.
        print("***** Extension of the local file picked (pickedFileType.preferredFilenameExtension): \(pickedFileExtension)")
        
        /// File type identifier
        print("#### Type identifier of the picked file: \(pickedFileTypeIdentifier)")
        
        // print("***** pickedFileType.referenceURL: \(pickedFileType.referenceURL)") // The value is null.
        
        // ***** Getting the (temporary) URL of the picked file *****
        ///loadInPlaceFileRepresentationForTypeIdentifier: is not supported. Use loadFileRepresentationForTypeIdentifier: instead.
        /// The function loadFileRepresentation() below, asynchronously writes a copy of the provided, typed data to a temporary file, returning a progress object.
        fileProvider.loadFileRepresentation(forTypeIdentifier: pickedFileType.identifier) { maybeURL, maybeError in
            if let error = maybeError {
                AlertManager.showAlert(myTitle: "Uploading error", myMessage: "Unable to get the URL of the local file.")
                print("Uploading error details: \(error.localizedDescription)")
                return
            }
            guard let pickedFileURL = maybeURL else {return}
            print("##### URL of the picked file: \(pickedFileURL)")
            print("#####Picked file last path component:\(pickedFileURL.lastPathComponent)")
            
            let pickedFileNameWithExtension = pickedFileURL.lastPathComponent
            
            // Uploading the picked file using its local temporary URL
            /// myStorageRef.child(fileStorageRoot).child("\(fileName).jpg")
            //myStorageRef.child(fileStorageRoot).child(pickedFileNameWithExtension).__putFile(from: pickedFileURL) // The file located at this URL is not reachable. (Maybe because it is not possible to do direct operations in files located in temp folders.)
            
            /// Note: putData should be used instead of putFile in Extensions. (Note that here PHPickerViewControllerDelegate is implemented as EXTENSION of HomeViewController).
            /// Because using putFile, the app try to access the file located in the local URL, but unfortunately (probably for security reasons), the file is not reacheable.
//            myStorageRef.child(fileStorageRoot).child(pickedFileNameWithExtension).putFile(from: pickedFileURL, metadata: pickedFileMetadata) { [self] maybeMetadata, maybeError in
//                
//                if let uploadingError = maybeError {
//                    AlertManager.showAlert(myTitle: "Upload error", myMessage: "Unable to upload the file. Error details: \(uploadingError.localizedDescription)")
//                    print("Unable to upload the file. Error details: \(uploadingError.localizedDescription)")
//                    return
//                }
//                
//                guard let uploadedFileMetadata = maybeMetadata else {return}
//                
//                AlertManager.showAlert(myTitle: "File uploaded", myMessage: "The file \"\(pickedFileNameWithExtension)\" has been successfully uploaded in the cloud.")
//                
//                print("### Name of the picked local file (pickedFileNameWithExtension): \(pickedFileNameWithExtension)")
//                print("### Metadata of the file stored in the cloud (uploadedFileMetadata): \(uploadedFileMetadata)")
//                
//                copyDataFromStorageToRealtimeDB()
//                
//                getFileNamesFromRealtimeDB()
//            }
        }
        
        /// Loading file data contained in "fileProvider".
        fileProvider.loadObject(ofClass: UIImage.self) { [self] wrappedFile, error in
            
            if let fileError = error {
                AlertManager.showAlert(myTitle: "Error while uploading the file", myMessage: "It seems that the file you selected is not an image/photo.")
                print("##### Error while uploading the file. It seems that the picked file is not an image/photo. Error details: \(fileError.localizedDescription)")
                return
            }
            
            // TODO: P0, Add code for also uploading video and any kind of media file stored in the gallery (Photos app).
            
            guard let pickedImage = wrappedFile as? UIImage else {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Error: Failed to cast the file as UIImage.")
                print("##### Error: Failed to cast the file as UIImage.")
                return
            }
            
            DispatchQueue.main.sync {
                uploadImageInCloudStorage(uIImageFile: pickedImage, fileName: pickedFileName)
            }
        }
        
        picker.dismiss(animated: true)
    }
}

