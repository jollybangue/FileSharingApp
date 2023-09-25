//
//  WebViewController.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-09-24.
//
// Some notes: UIWebView is deprecated since iOS 12. When using it in this app, it is possible to open all the files, but it is not possible to scroll nor zoom in nor zoom out
// WKWebView is perfect. It opens all the files, is more stable and also the scroll and zoom control is working. The opened picture is automatically fit to the screen (which is not the case with UIWebView).

import UIKit
import WebKit
import FirebaseStorage

class WebViewController: UIViewController {
    
    //@IBOutlet weak var myWebView: UIWebView!
    //@IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var myWebKitView: WKWebView!
    
    var fileReference: StorageReference?
        
    var selectedFileName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = selectedFileName
        
        guard let fileRef = fileReference else {
            AlertManager.showAlert(myTitle: "Error", myMessage: "Unable to get the reference of the file to display.")
            return
        }
        
        fileRef.downloadURL { [self] maybeURL, maybeError in
            if let error = maybeError {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Unable to get the URL of the selected file.")
                print("##### Error: \(error.localizedDescription)")
                return
            }
            
            guard let myURL = maybeURL else {
                AlertManager.showAlert(myTitle: "Error", myMessage: "Something went wrong while unwrapping the URL.")
                return
            }
            
            myWebKitView.load(URLRequest(url: myURL))
            
            print("File link loaded in both web views: \(myURL)")
        }
    }
}
