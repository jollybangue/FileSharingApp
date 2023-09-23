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

class FileViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    //@IBOutlet weak var fileNameLabel: UILabel!
    
    var fileReference: StorageReference?
        
    var selectedFileName: String = ""
    
    var imageToDisplay = UIImage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = selectedFileName
        
        guard let fileRef = fileReference else {
            AlertManager.showAlert(myTitle: "Error", myMessage: "Unable to get the reference of the file to display.")
            return
        }
        
        fileRef.getData(maxSize: (10 * 1024 * 1024)) { [self] maybeData, maybeError in
            
            if let error = maybeError {
                AlertManager.showAlert(myTitle: "Error", myMessage: "There was an error while opening the selected file.")
                print("Error details: \(error.localizedDescription)")
                return
            }
            
            guard let downloadedFileData = maybeData else {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Something went wrong while unwrapping the downloaded file data...")
                return
            }
            
            imageView.image = UIImage(data: downloadedFileData)
        }
        
        
    }

}
