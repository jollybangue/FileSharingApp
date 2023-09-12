//
//  SceneDelegate.swift
//  FileSharingApp
//
//  Created by Jolly BANGUE on 2023-08-27.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        //guard let _ = (scene as? UIWindowScene) else { return }
        
        /// With the code below, if the user is already logged in to the server, they will directly get the Home Screen when launching the app
        /// If the user is not yet logged in, they will get the Login Screen when launching the app.
        guard let windowScene = scene as? UIWindowScene else {return}
        
        Auth.auth().addStateDidChangeListener { _, currentUser in
            if currentUser != nil {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController
                let myRootViewController = storyboard.instantiateViewController(withIdentifier: "HomeVC") as UIViewController
                navigationController?.viewControllers = [myRootViewController]
                let window = UIWindow(windowScene: windowScene)
                window.rootViewController = navigationController
                self.window = window
                window.makeKeyAndVisible()
                
            }
            guard let userEmail = currentUser?.email else {
                /// Printing a message test in console just for debugging
                print("Message from SceneDelegate: The current logged in user is \(String(describing: currentUser?.email))")
                return
            }
            /// Printing a message test in console just for debugging
            print("Message from SceneDelegate: Welcome \(userEmail)")
            
        }

    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

