//
//  SettingsVC.swift
//  WeatherApp
//
//  Created by George Davies on 26/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

let settingsDataNCKey = "com.georgeddavies.settingsData"

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
            
    @IBOutlet weak var daysToForecastTextField: UITextField!
    @IBOutlet weak var voiceLocaleTextField: UITextField!
    @IBOutlet weak var locationsTableView: UITableView!
    @IBOutlet weak var hourlyForecastSwitch: UISwitch!
    
    var userSettingsDict = [String : Any]()
    
    var ref: FIRDatabaseReference!
    private var databaseHandle: FIRDatabaseHandle!
    var locationsArray = [CLLocation]()
    var selectedLocation: CLLocation?
    var cityNamesArray = [String]()
    var selectedCityName: String?
    
    let defaults = UserDefaults.standard
    
    var localeOptions = ["en-GB", "en-AU", "en-IE", "en-US", "en-ZA"]
        
    @IBAction func saveSettingsButton(_ sender: UIBarButtonItem) {
        
        var userDict = [String : Any]()
        
        if daysToForecastTextField.text != "" {
            userDict["daysToForecast"] = Int(daysToForecastTextField.text!)
        }
        userDict["locale"] = voiceLocaleTextField.text
        
        if hourlyForecastSwitch.isOn {
            userDict["hourlyForecast"] = true
        } else {
            userDict["hourlyForecast"] = false
        }
        
        //userDict["userID"] = AuthenticationManager.sharedInstance.userId!
        
        self.defaults.set(userDict, forKey: AuthenticationManager.sharedInstance.userId!)
        self.defaults.synchronize()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: settingsDataNCKey), object: self)     
    }
    
    @IBAction func logOutAction(_ sender: UIButton) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            AuthenticationManager.sharedInstance.loggedIn = false
            self.performSegue(withIdentifier: "UnwindToStartingVC", sender: self)
        } catch let signOutError as NSError {
            print ("Error signing out: \(signOutError)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViewController()
        ref = FIRDatabase.database().reference()
        populateLocationsArray()
        populateTextFields()
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(donePicker))
        
        doneButton.tintColor = themeColour
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        voiceLocaleTextField.inputView = pickerView
        voiceLocaleTextField.inputAccessoryView = toolBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print(userSettingsDict)
    }
    
    func donePicker() {
        voiceLocaleTextField.resignFirstResponder()
    }
    
    func setUpViewController() {
        navigationController?.navigationBar.barTintColor = themeColour
        self.locationsTableView.allowsMultipleSelection = false
        //locationsTableView.selectRow(at: selectedUserIndex, animated: false, scrollPosition: .top)
        daysToForecastTextField.tag = 0
    }
        
    func populateLocationsArray() {
        
        // Download locations from Firebase that are associated with the signed in user
        
        locationsArray.removeAll()
        databaseHandle = ref.child("locations").observe(.childAdded, with: { (snapshot) -> Void in
            if let value = snapshot.value as? [String : Any] {
                value.forEach( { (name, loc) in
                    // Selected city = Name
                    let locDict = loc as? [String : Double]
                    if let latitude = locDict?["locationLatitude"] {
                        if let longitude = locDict?["locationLongitude"] {
                            self.cityNamesArray.append(name)
                            let location = CLLocation(latitude: latitude, longitude: longitude)
                            self.locationsArray.append(location)
                        }
                    }
                })
                self.locationsTableView.reloadData()
            }
        })
    }
    
    func populateTextFields() {
        if let days = userSettingsDict["daysToForecast"] as? Int {
            daysToForecastTextField.text = String(describing: days)
        }
        if let savedLocale = userSettingsDict["locale"] as? String {
            voiceLocaleTextField.text = savedLocale
        }
        if let hourly = userSettingsDict["hourlyForecast"] as? Bool {
            hourlyForecastSwitch.isOn = hourly

        }
    }
    
    // Make sure number of days is <= 16
    func daysToForecastIsValid(settingsArray: Array<String>) -> Bool {
        let days = Int(settingsArray[0])
        if days! > 16 {
            displayPopUp(title: "Invalid days to forecast", message: "Please enter a number up to and including 16", placeHolder: "")
            return false
        }
        return true
    }

    
    // MARK: - Tableview methods
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Saved Locations"
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
        return locationsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        
        cell.textLabel?.text = cityNamesArray[indexPath.row]
        
        cell.accessoryType = cell.isSelected ? .checkmark : .none

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        locationsTableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        selectedLocation = locationsArray[indexPath.row]
        selectedCityName = cityNamesArray[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        locationsTableView.cellForRow(at: indexPath)?.accessoryType = .none
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
    
    // MARK: - Reusable popup
    func displayPopUp(title: String, message: String, placeHolder: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.dismiss(animated: true, completion: {
            })
        }))
    
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            self.dismiss(animated: true, completion: {
            })
        }))
    
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowWeatherCollectionVC" {
            
        }
    }
    
//    override func unwind(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
//        <#code#>
//    }
//    
//    override func performSegue(withIdentifier identifier: String, sender: Any?) {
//        <#code#>
//    }
}
