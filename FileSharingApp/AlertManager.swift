//
//  AlertManager.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-09-04.
/// A class for managing alerts

import Foundation
import UIKit


class AlertManager {
    
    class func showAlert(myTitle: String, myMessage: String) {
        
        let alertController = UIAlertController(title: myTitle, message: myMessage, preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default)
        
        let myRootViewController = UIApplication.shared.keyWindow?.rootViewController
        
        alertController.addAction(OKAction)
        
        myRootViewController?.present(alertController, animated: true)
    }
    
    //class func confirmationAlert() {} I can define it later, to manage multiple confirmation alerts.
    
}
