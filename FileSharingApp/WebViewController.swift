//
//  WebViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-09-24.
//
// NOTES: UIWebView is deprecated since iOS 12. When using it in this app, it is possible to open all the files, but it is not possible to scroll nor zoom in nor zoom out
// WKWebView is better. It opens all the files, is more stable and also the scroll and zoom control is working fine. The opened picture is automatically fit to the screen (which is not the case with UIWebView).


import UIKit
import WebKit
import FirebaseStorage

class WebViewController: UIViewController {
    
    @IBOutlet weak var myWebKitView: WKWebView!
    
    /// fileReference will be assigned a value while performing the segue "showWebView" in HomeViewController.
    var fileReference: StorageReference?
        
    /// selectedFileName will be assigned a value (name of the file selected) while performing the segue "showWebView" in HomeViewController.
    var selectedFileName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        navigationItem.title = selectedFileName
        
        /// Unwrapping the reference of the file to be opened in WKWebView.
        guard let fileRef = fileReference else {
            AlertManager.showAlert(myTitle: "Error", myMessage: "Unable to get the reference of the file to display in WebKit View.")
            return
        }
        
        fileRef.downloadURL { [self] maybeURL, maybeError in
            
            if let error = maybeError {
                AlertManager.showAlert(myTitle: "URL Download Error", myMessage: error.localizedDescription)
                return
            }
            
            guard let cloudStorageURL = maybeURL else {return}
            
            myWebKitView.load(URLRequest(url: cloudStorageURL))
            
            print("Cloud Storage URL of the file loaded in WebKit View: \(cloudStorageURL)")
        }
    }
}
