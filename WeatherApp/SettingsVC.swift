//
//  SettingsVC.swift
//  WeatherApp
//
//  Created by George Davies on 26/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var daysToForecastTextField: UITextField!
    @IBOutlet weak var voiceLocaleTextField: UITextField!
    @IBOutlet weak var usersTableView: UITableView!
    
    var userArray = [Dictionary<String, Any>]()
    let defaults = UserDefaults.standard
    var selectedUserIndex = IndexPath(row: 0, section: 0)
    
    @IBAction func addUserButton(_ sender: UIBarButtonItem) {
        addUser(sender: sender)
    }
    
    @IBAction func saveSettingsButton(_ sender: UIButton) {
        let newSettings = getTextFieldText()
        userArray[selectedUserIndex.row]["daysToForecast"] = Int(newSettings[0])
        userArray[selectedUserIndex.row]["locale"] = newSettings[1]
        
        self.defaults.set(self.userArray, forKey: "Users")
        self.defaults.synchronize()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.usersTableView.allowsMultipleSelection = false
        populateUsers()
        usersTableView.selectRow(at: selectedUserIndex, animated: false, scrollPosition: .top)
        userArray[selectedUserIndex.row]["isSelected"] = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addDefaultUser() {
        let userDict = ["Username": "Default User",
                        "daysToForecast": 10,
                        "locale": "en-GB",
                        "isSelected": true
            ] as [String : Any]
        self.userArray.append(userDict)
        self.defaults.set(self.userArray, forKey: "Users")
        self.defaults.synchronize()
        self.usersTableView.reloadData()
    }
    
    func getSelectedUser() {
        
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
                    i = i + 1
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
    
    func addUser(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add User", message: "Enter the new user's name below", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "e.g. Matt"
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak alert] (_) in
            let textFieldText = alert?.textFields![0].text
            
            let userDict = ["Username": textFieldText!,
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
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func userAlreadyExist(userKey: String) -> Bool {
        return UserDefaults.standard.object(forKey: userKey) != nil
    }
    
    func getTextFieldText() -> Array<String> {
        
        // Populate array with existing saved/default values
        var textFieldArray = ["10","en-GB"]
        
        if daysToForecastTextField.text != "" {
            textFieldArray[0] = daysToForecastTextField.text!
        }
        
        if voiceLocaleTextField.text != "" {
            textFieldArray[1] = voiceLocaleTextField.text!
        }
        
        return textFieldArray
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
        cell.textLabel?.text = String(describing: userArray[indexPath.row]["Username"]!)
        cell.accessoryType = cell.isSelected ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        usersTableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        selectedUserIndex = indexPath
        
        userArray[indexPath.row]["isSelected"] = true
        self.defaults.set(self.userArray, forKey: "Users")
        self.defaults.synchronize()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        usersTableView.cellForRow(at: indexPath)?.accessoryType = .none
        
        userArray[indexPath.row]["isSelected"] = false
        self.defaults.set(self.userArray, forKey: "Users")
        self.defaults.synchronize()
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
