//
//  ImageViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-08-28.
//

import UIKit
import FirebaseStorage

class ImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    /// fileReference will be assigned a value while performing the segue "showImage" in HomeViewController.
    var fileReference: StorageReference?
        
    /// selectedFileName will be assigned a value (name of the file selected) while performing the segue "showImage" in HomeViewController.
    var selectedFileName: String = ""
        
    override func viewDidLoad() {
        super.viewDidLoad()
                
        navigationItem.title = selectedFileName
        
        guard let fileRef = fileReference else {
            AlertManager.showAlert(myTitle: "Error", myMessage: "Unable to get the reference of the file to display in ImageView.")
            return
        }
        
        /// Download in memory (RAM I guess) a file with max size limited to 50 MB.
        fileRef.getData(maxSize: (50 * 1024 * 1024)) { [self] maybeData, maybeError in
            
            if let error = maybeError {
                AlertManager.showAlert(myTitle: "Image Loading Error", myMessage: error.localizedDescription)
                return
            }
            
            guard let downloadedFileData = maybeData else {return}
            
            /// Loads and shows the downloaded image in imageView
            imageView.image = UIImage(data: downloadedFileData)
        }
        
    }

}
