//
//  LoginVC.swift
//  WeatherApp
//
//  Created by George Davies on 30/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import UIKit
import Firebase

class LoginVC: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBAction func didTapLogin(sender: UIButton) {
        guard let email = emailField.text, let password = passwordField.text, email.characters.count > 0, password.characters.count > 0 else {
            self.showAlert(message: "Enter an email and a password.")
            return
        }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
            if let error = error {
                if error._code == FIRAuthErrorCode.errorCodeUserNotFound.rawValue {
                    self.showAlert(message: "There are no users with the specified account.")
                } else if error._code == FIRAuthErrorCode.errorCodeWrongPassword.rawValue {
                    self.showAlert(message: "Incorrect username or password.")
                } else {
                    self.showAlert(message: "Error: \(error.localizedDescription)")
                }
                print(error.localizedDescription)
                return
            }
            
            if let user = user {
                AuthenticationManager.sharedInstance.didLogIn(user: user)
                self.performSegue(withIdentifier: "ShowWeatherFromLogin", sender: nil)
                self.emailField.text = ""
                self.passwordField.text = ""
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.text = "s@s.com"
        passwordField.text = "123456"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "WeatherApp", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
