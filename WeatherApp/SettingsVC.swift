//
//  SettingsVC.swift
//  WeatherApp
//
//  Created by George Davies on 26/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import UIKit

let settingsDataNCKey = "com.georgeddavies.settingsData"

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var daysToForecastTextField: UITextField!
    @IBOutlet weak var voiceLocaleTextField: UITextField!
    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var hourlyForecastSwitch: UISwitch!
    
    var userArray = [Dictionary<String, Any>]()
    let defaults = UserDefaults.standard
    var selectedUserIndex = IndexPath(row: 0, section: 0)
    
    var localeOptions = ["en-GB", "en-AU", "en-IE", "en-US", "en-ZA"]
    
    @IBAction func addUserButton(_ sender: UIBarButtonItem) {
        addUser(sender: sender)
    }
    
    @IBAction func saveSettingsButton(_ sender: UIBarButtonItem) {
        if daysToForecastTextField.text != "" {
            userArray[selectedUserIndex.row]["daysToForecast"] = Int(daysToForecastTextField.text!)
        }
        userArray[selectedUserIndex.row]["locale"] = voiceLocaleTextField.text
        
        if hourlyForecastSwitch.isOn {
            userArray[selectedUserIndex.row]["hourlyForecast"] = true
        } else {
            userArray[selectedUserIndex.row]["hourlyForecast"] = false
        }
        
        self.defaults.set(self.userArray, forKey: "Users")
        self.defaults.synchronize()
        NotificationCenter.default.post(name: Notification.Name(rawValue: settingsDataNCKey), object: self)
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        populateUsers()
        setUpViewController()
        populateTextFields()
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        voiceLocaleTextField.inputView = pickerView
    }
    
    func setUpViewController() {
        navigationController?.navigationBar.barTintColor = themeColour
        self.usersTableView.allowsMultipleSelection = false
        usersTableView.selectRow(at: selectedUserIndex, animated: false, scrollPosition: .top)
        userArray[selectedUserIndex.row]["isSelected"] = true
        daysToForecastTextField.tag = 0
    }
    
    // Save default user to user array with default values
    func addDefaultUser() {
        let userDict = ["username": "Default User",
                        "daysToForecast": 10,
                        "locale": "en-GB",
                        "isSelected": true,
                        "hourlyForecast": false
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
                // Loop through users
                for user in element.value as! Array<[String:Any]> {
                    // Add user to array of users
                    userArray.append(user)
                    // Check if user is selected
                    if user["isSelected"] as? Bool == true {
                        // If user is selected, save IndexPath
                        numOfSelectedUsers = 1
                        selectedUserIndex = IndexPath(row: i, section: 0)
                    }
                    i += 1
                }
            }
        }
        // If no users exist, add default user
        if userArray.count == 0 {
            addDefaultUser()
        }
        
        // If no users are selected then select first user
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
        let hourly = userArray[selectedUserIndex.row]["hourlyForecast"] as? Bool

        daysToForecastTextField.text = String(describing: days!)
        voiceLocaleTextField.text = savedLocale!
        hourlyForecastSwitch.isOn = hourly!
    }
    
    func addUser(sender: UIBarButtonItem) {
        displayPopUp(title: "Add User", message: "Enter the new user's name below", placeHolder: "e.g. Matt", type: "Save")
    }
    
    // Make sure number of days is <= 16
    func daysToForecastIsValid(settingsArray: Array<String>) -> Bool {
        let days = Int(settingsArray[0])
        if days! > 16 {
            displayPopUp(title: "Invalid days to forecast", message: "Please enter a number up to and including 16", placeHolder: "", type: "Standard")
            return false
        }
        return true
    }

    
    // MARK: - Tableview methods
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Users"
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        if let username = userArray[indexPath.row]["username"] {
            cell.textLabel?.text = String(describing: username)
        }
        cell.accessoryType = cell.isSelected ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        usersTableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        selectedUserIndex = indexPath
        saveIsUserSelected(userIndexPath: indexPath, isSelected: true)
        populateTextFields()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        usersTableView.cellForRow(at: indexPath)?.accessoryType = .none
        saveIsUserSelected(userIndexPath: indexPath, isSelected: false)
    }
    
    func saveIsUserSelected(userIndexPath: IndexPath, isSelected: Bool) {
        userArray[userIndexPath.row]["isSelected"] = isSelected
        self.defaults.set(self.userArray, forKey: "Users")
        self.defaults.synchronize()
    }
    
    // MARK: - Textfield methods

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
    
    // MARK: - Reusable popup view
    
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
                                "isSelected": true,
                                "hourlyForecast": false
                    ] as [String : Any]
                self.userArray.append(userDict)
                self.defaults.set(self.userArray, forKey: "Users")
                self.defaults.synchronize()
                self.usersTableView.reloadData()
                self.usersTableView.selectRow(at: self.selectedUserIndex, animated: false, scrollPosition: .top)
            }))
        
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                self.dismiss(animated: true, completion: {
                })
            }))
        } else {
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: {
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
}
