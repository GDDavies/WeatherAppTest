//
//  SettingsVC.swift
//  WeatherApp
//
//  Created by George Davies on 26/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var daysToForecastTextField: UITextField!
    @IBOutlet weak var voiceLocaleTextField: UITextField!
    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var saveButtonBottomLayoutConstraint: NSLayoutConstraint!
    
    var userArray = [Dictionary<String, Any>]()
    let defaults = UserDefaults.standard
    var selectedUserIndex = IndexPath(row: 0, section: 0)
    
    var localeOptions = ["en-GB", "en-AU", "en-IE", "en-US", "en-ZA"]
    
    @IBAction func addUserButton(_ sender: UIBarButtonItem) {
        addUser(sender: sender)
    }
    
    @IBAction func saveSettingsButton(_ sender: UIButton) {
        if daysToForecastTextField.text != "" {
            userArray[selectedUserIndex.row]["daysToForecast"] = Int(daysToForecastTextField.text!)
        }
        userArray[selectedUserIndex.row]["locale"] = voiceLocaleTextField.text
        
        self.defaults.set(self.userArray, forKey: "Users")
        self.defaults.synchronize()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)

        self.usersTableView.allowsMultipleSelection = false
        populateUsers()
        usersTableView.selectRow(at: selectedUserIndex, animated: false, scrollPosition: .top)
        userArray[selectedUserIndex.row]["isSelected"] = true
        daysToForecastTextField.tag = 0
        
        populateTextFields()
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        voiceLocaleTextField.inputView = pickerView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addDefaultUser() {
        let userDict = ["username": "Default User",
                        "daysToForecast": 10,
                        "locale": "en-GB",
                        "isSelected": true
            ] as [String : Any]
        self.userArray.append(userDict)
        self.defaults.set(self.userArray, forKey: "Users")
        self.defaults.synchronize()
        self.usersTableView.reloadData()
    }
    
    func populateUsers() {
        var numOfSelectedUsers = 0
        for element in UserDefaults.standard.dictionaryRepresentation() {
            if element.key == "Users" {
                var i = 0
                for user in element.value as! Array<[String:Any]> {
                    userArray.append(user)
                    if user["isSelected"] as? Bool == true {
                        numOfSelectedUsers = 1
                        selectedUserIndex = IndexPath(row: i, section: 0)
                    }
                    i += 1
                }
            }
        }
        if userArray.count == 0 {
            addDefaultUser()
        }
        if numOfSelectedUsers == 0 {
            selectedUserIndex = IndexPath(row: 0, section: 0)
            userArray[selectedUserIndex.row]["isSelected"] = true
            self.defaults.set(self.userArray, forKey: "Users")
            self.defaults.synchronize()
        }
        usersTableView.reloadData()
    }
    
    func populateTextFields() {
        let days = userArray[selectedUserIndex.row]["daysToForecast"] as? Int
        let savedLocale = userArray[selectedUserIndex.row]["locale"] as? String
        daysToForecastTextField.text = String(describing: days!)
        voiceLocaleTextField.text = savedLocale!
    }
    
    func addUser(sender: UIBarButtonItem) {
        displayPopUp(title: "Add User", message: "Enter the new user's name below", placeHolder: "e.g. Matt", type: "Save")
    }
    
    func userAlreadyExist(userKey: String) -> Bool {
        return UserDefaults.standard.object(forKey: userKey) != nil
    }
    
    func daysToForecastIsValid(settingsArray: Array<String>) -> Bool {
        let days = Int(settingsArray[0])
        if days! > 16 {
            displayPopUp(title: "Invalid days to forecast", message: "Please enter a number up to and including 16", placeHolder: "", type: "Standard")
            return false
        }
        return true
    }

    
    // MARK: - Tableview methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        cell.textLabel?.text = String(describing: userArray[indexPath.row]["username"]!)
        cell.accessoryType = cell.isSelected ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        usersTableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        selectedUserIndex = indexPath
        
        userArray[indexPath.row]["isSelected"] = true
        self.defaults.set(self.userArray, forKey: "Users")
        self.defaults.synchronize()

        populateTextFields()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        usersTableView.cellForRow(at: indexPath)?.accessoryType = .none
        
        userArray[indexPath.row]["isSelected"] = false
        self.defaults.set(self.userArray, forKey: "Users")
        self.defaults.synchronize()
    }
    
    // MARK: - Textfield Methods

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == 0 {
            
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet) && newLength <= 2
        }
        return false
    }
    
    func displayPopUp(title: String, message: String, placeHolder: String, type: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if type == "Save" {
            alert.addTextField { (textField) in
                textField.placeholder = placeHolder
            }
            alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak alert] (_) in
                let textFieldText = alert?.textFields![0].text
                
                let userDict = ["username": textFieldText!,
                                "daysToForecast": 10,
                                "locale": "en-GB",
                                "isSelected": true
                    ] as [String : Any]
                self.userArray.append(userDict)
                self.defaults.set(self.userArray, forKey: "Users")
                self.defaults.synchronize()
                self.usersTableView.reloadData()
                self.usersTableView.selectRow(at: self.selectedUserIndex, animated: false, scrollPosition: .top)
            }))
        
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                self.dismiss(animated: true, completion: {
                    print("Cancel")
                })
            }))
        } else {
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: {
                print("OK")
                })
            }))
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Picker methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return localeOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return localeOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        voiceLocaleTextField.text = localeOptions[row]
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.saveButtonBottomLayoutConstraint?.constant = 0.0
            } else {
                self.saveButtonBottomLayoutConstraint?.constant = endFrame?.size.height ?? 0.0
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
}