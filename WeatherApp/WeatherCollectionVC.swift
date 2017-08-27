//
//  WeatherCollectionVC.swift
//  WeatherApp
//
//  Created by George Davies on 25/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation

class WeatherCollectionVC: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate {

    @IBOutlet weak var weatherCollectionView: UICollectionView!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var shareWeatherButton: UIBarButtonItem!
    
    // MARK: - Properties
    fileprivate let reuseIdentifier = "DayCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    fileprivate let itemsPerRow: CGFloat = 2
    
    fileprivate let locationManager = CLLocationManager()
    var selectedIndex: IndexPath?
    
    var startingLocation: CLLocation?
    var newLocation: CLLocation?
    var newCityName: String?
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        if let origin = segue.source as? MapViewVC {
            newLocation = origin.newLocation
            newCityName = origin.newCityName
            if let latitude = newLocation?.coordinate.latitude {
                WeatherData.sharedInstance.getWeatherData(latitude: latitude, longitude: (newLocation?.coordinate.longitude)!)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        findLocation()
        
        // Notification observer for when settings are updated
        NotificationCenter.default.addObserver(self, selector: #selector(populateData), name: NSNotification.Name(rawValue: settingsDataNCKey), object: nil)
        
        // Notification observer for when json data is successfully loaded
        NotificationCenter.default.addObserver(self, selector: #selector(shouldPopulateData), name: NSNotification.Name(rawValue: weatherDataNCKey), object: nil)
        
        shareWeatherButton.isEnabled = false
        weatherCollectionView.allowsMultipleSelection = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func shouldPopulateData() {
        
        if WeatherData.sharedInstance.daysCount != weatherCollectionView.numberOfItems(inSection: 0) {
            populateData()
        }
        if newLocation != nil {
            if cityNameLabel.text != newCityName {
                populateData()
            }
        }
    }
    
    func populateData() {
        WeatherData.sharedInstance.getLocaleAndDaysToForecast()
        if newLocation == nil {
            if let start = startingLocation {
                WeatherData.sharedInstance.getWeatherData(latitude: start.coordinate.latitude, longitude: start.coordinate.longitude)
            }
        } else {
            if let new = newLocation {
                WeatherData.sharedInstance.getWeatherData(latitude: new.coordinate.latitude, longitude: new.coordinate.longitude)
            }
        }
        weatherCollectionView.reloadData()
        updateCollectionViewLabels()
    }
    
    func findLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: " + error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        CLGeocoder().reverseGeocodeLocation(manager.location!) { (placemarks, error) in
            if (error != nil) {
                print("Error: " + error!.localizedDescription)
                return
            }
            if placemarks!.count > 0 {
                let placemark = placemarks![0] as CLPlacemark
                self.getLocationDetails(placemark: placemark, location: manager.location!)
            } else {
                print("Error retrieving data")
            }
        }
    }
    
    func getLocationDetails(placemark: CLPlacemark, location: CLLocation) {
        locationManager.stopUpdatingLocation()
        startingLocation = location
        WeatherData.sharedInstance.getWeatherData(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    func updateCollectionViewLabels() {
        if let cityName = newCityName {
            WeatherData.sharedInstance.city = cityName
            cityNameLabel.text = cityName
        } else {
            cityNameLabel.text = WeatherData.sharedInstance.city
        }
        weatherCollectionView.reloadData()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowMapView" {
            if let destinationVC = segue.destination as? MapViewVC {
                destinationVC.location = locationManager.location
            }
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return WeatherData.sharedInstance.weatherArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! WeatherCollectionViewCell
        cell.backgroundColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)
        
        if !cell.isSelected {
            cell.layer.borderWidth = 0.0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
        
        if !WeatherData.sharedInstance.weatherArray.isEmpty {
            if let weatherDate = WeatherData.sharedInstance.weatherArray[indexPath.row].date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d MMM"
                cell.dateLabel.text = dateFormatter.string(from: weatherDate)
            }
            if let weatherIcon = WeatherData.sharedInstance.weatherArray[indexPath.row].weatherIcon {
                let image = UIImage(named: "\(weatherIcon).png")
                let templateImage = image?.withRenderingMode(.alwaysTemplate)
                cell.weatherTypeIcon.image = templateImage
                cell.weatherTypeIcon.tintColor = UIColor.white
            }
            if let minTemp = WeatherData.sharedInstance.weatherArray[indexPath.row].minTemp {
                cell.minTempLabel.text = "Min: \(String(format: "%.0f", minTemp))°C"
            }
            if let maxTemp = WeatherData.sharedInstance.weatherArray[indexPath.row].maxTemp {
                cell.maxTempLabel.text = "Max: \(String(format: "%.0f", maxTemp))°C"
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = weatherCollectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.lightGray.cgColor
        cell!.layer.borderWidth = 3.0
        if !shareWeatherButton.isEnabled {
            shareWeatherButton.isEnabled = true
        }
        textToSpeech(index: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = weatherCollectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.clear.cgColor
        cell!.layer.borderWidth = 0.0
    }
    
    @IBAction func shareWeatherAction(_ sender: UIBarButtonItem) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM"
        if let weatherDate = WeatherData.sharedInstance.weatherArray[(selectedIndex?.row)!].date {
            if let weatherDesc = WeatherData.sharedInstance.weatherArray[(selectedIndex?.row)!].weatherDescription {
                let stringToShareArray = [dateFormatter.string(from: weatherDate), weatherDesc]
                let activityVC = UIActivityViewController(activityItems: stringToShareArray, applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = view
                self.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    func textToSpeech(index: IndexPath) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM"
        if let weatherDate = WeatherData.sharedInstance.weatherArray[index.row].date {
            if let weatherDesc = WeatherData.sharedInstance.weatherArray[index.row].weatherDescription {
                let string = "\(dateFormatter.string(from: weatherDate)) \(weatherDesc). Highs of\(String(format: "%.0f", WeatherData.sharedInstance.weatherArray[index.row].maxTemp!)) degrees celsius and lows of \(String(format: "%.0f", WeatherData.sharedInstance.weatherArray[index.row].minTemp!)) degrees celsius."
                let utterance = AVSpeechUtterance(string: string)
                utterance.voice = AVSpeechSynthesisVoice(language: WeatherData.sharedInstance.voiceLocale)
                let synthesizer = AVSpeechSynthesizer()
                synthesizer.speak(utterance)
                selectedIndex = index
            }
        }
    }
    
    
//    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
//        <#code#>
//    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
