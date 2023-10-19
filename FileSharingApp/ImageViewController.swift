//
//  ImageViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-08-28.
//
// TODO: In the future, instead of an ImageView, I should implement here a Web View or a WebKit View, to be able to open not only image (Jpeg, PNG, BMP, ...), but also PDF and many other kind of files.

// TODO: In the future, try to use FirebaseUI...

import UIKit
import FirebaseStorage

class ImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var fileReference: StorageReference?
        
    var selectedFileName: String = ""
        
    override func viewDidLoad() {
        super.viewDidLoad()
                
        navigationItem.title = selectedFileName
        
        guard let fileRef = fileReference else {
            AlertManager.showAlert(myTitle: "Error", myMessage: "Unable to get the reference of the file to display.")
            return
        }
        
        /// Download in memory (RAM I guess) a file with max size limited to 10 MB
        fileRef.getData(maxSize: (50 * 1024 * 1024)) { [self] maybeData, maybeError in
            
            if let error = maybeError {
                AlertManager.showAlert(myTitle: "Error", myMessage: "There was an error while opening the selected file.")
                print("Error details: \(error.localizedDescription)")
                return
            }
            
            guard let downloadedFileData = maybeData else {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Something went wrong while unwrapping the downloaded file data...")
                return
            }
            
            /// Loads and shows the downloaded image in imageView
            imageView.image = UIImage(data: downloadedFileData)
        }
        
        
    }

}
