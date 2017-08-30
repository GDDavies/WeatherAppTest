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

let themeColour = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)

class WeatherCollectionVC: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate, AVSpeechSynthesizerDelegate {

    @IBOutlet weak var weatherCollectionView: UICollectionView!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var shareWeatherButton: UIBarButtonItem!
    
    // MARK: - Properties
    fileprivate let reuseIdentifier = "DayCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    fileprivate var itemsPerRow: CGFloat = 2.0
    fileprivate let dayForecastFormat = "d MMM"
    fileprivate let hourlyForecastFormat = "d MMM - h:mm a"
    
    let dateFormatter = DateFormatter()
    
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
        mainViewSetup()
        findLocation()
        loadingScreenViews()
        WeatherData.sharedInstance.getLocaleAndDaysToForecast()
        audioToMainSpeaker()
        
        navigationController?.navigationBar.tintColor = UIColor.white
        
        // Notification observer for when settings are updated
        NotificationCenter.default.addObserver(self, selector: #selector(populateData), name: NSNotification.Name(rawValue: settingsDataNCKey), object: nil)
        
        // Notification observers for when json data is successfully loaded
        NotificationCenter.default.addObserver(self, selector: #selector(shouldPopulateData), name: NSNotification.Name(rawValue: weatherDataNCKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldPopulateData), name: NSNotification.Name(rawValue: hourlyDataNCKey), object: nil)
    }
    
    // MARK: - Setup views
    
    func mainViewSetup() {
        navigationController?.navigationBar.barTintColor = themeColour
        cityNameLabel.textColor = themeColour
        shareWeatherButton.isEnabled = false
        weatherCollectionView.allowsMultipleSelection = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        weatherCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    // Loading view to be displayed until weather forecast views have been updated
    func loadingScreenViews() {
        let screenSize: CGRect = UIScreen.main.bounds
        let loadingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        loadingView.backgroundColor = .white
        loadingView.alpha = 1.0
        loadingView.tag = 100
        loadingView.isUserInteractionEnabled = true
        self.view.addSubview(loadingView)
        
        let myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        myActivityIndicator.center = view.center
        myActivityIndicator.startAnimating()
        myActivityIndicator.tag = 200
        view.addSubview(myActivityIndicator)
    }
    
    // MARK: - Populate data from API
    
    func shouldPopulateData() {
        if !WeatherData.sharedInstance.hourlyForecast {
            if WeatherData.sharedInstance.daysCount != weatherCollectionView.numberOfItems(inSection: 0) {
                animateLoadingScreenOut()
            }
            updateLocationNameIfChanged()
        } else {
            if WeatherData.sharedInstance.hourlyWeather.count != weatherCollectionView.numberOfItems(inSection: 0) {
                animateLoadingScreenOut()
            }
        }
        updateLocationNameIfChanged()
    }
    
    func animateLoadingScreenOut() {
        if let viewWithTag = self.view.viewWithTag(100) {
            UIView.animate(withDuration: 0.3, animations: {
                viewWithTag.alpha = 0.0
            }, completion: { (value: Bool) in
                viewWithTag.removeFromSuperview()
            })
        }
        if let viewWithTag = self.view.viewWithTag(200) {
            viewWithTag.removeFromSuperview()
        }
        populateData()
    }
    
    func updateLocationNameIfChanged() {
        if newLocation != nil {
            if cityNameLabel.text != newCityName {
                populateData()
            }
        }
    }
    
    func populateData() {
        WeatherData.sharedInstance.getLocaleAndDaysToForecast()
        if !WeatherData.sharedInstance.hourlyForecast {
            if newLocation == nil {
                if let start = startingLocation {
                    WeatherData.sharedInstance.getWeatherData(latitude: start.coordinate.latitude, longitude: start.coordinate.longitude)
                }
            } else {
                if let new = newLocation {
                    WeatherData.sharedInstance.getWeatherData(latitude: new.coordinate.latitude, longitude: new.coordinate.longitude)
                }
            }
        } else {
            if newLocation == nil {
                if let start = startingLocation {
                    WeatherData.sharedInstance.getHourlyForecast(latitude: start.coordinate.latitude, longitude: start.coordinate.longitude)
                }
            } else {
                if let new = newLocation {
                    WeatherData.sharedInstance.getHourlyForecast(latitude: new.coordinate.latitude, longitude: new.coordinate.longitude)
                }
            }
        }
        weatherCollectionView.reloadData()
        updateCollectionViewLabels()
    }
    
    // MARK: - Location methods
    
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
        WeatherData.sharedInstance.getHourlyForecast(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
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
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !WeatherData.sharedInstance.hourlyForecast {
            return WeatherData.sharedInstance.weatherArray.count
        } else {
            return WeatherData.sharedInstance.hourlyWeather.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! WeatherCollectionViewCell
        cell.backgroundColor = themeColour
        cell.weatherTypeIcon.tintColor = UIColor.white
        
        if !cell.isSelected {
            cell.layer.borderWidth = 0.0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
        
        // If daily forecast
        if !WeatherData.sharedInstance.hourlyForecast {
            if !WeatherData.sharedInstance.weatherArray.isEmpty {
                if let weatherDate = WeatherData.sharedInstance.weatherArray[indexPath.row].date {
                    dateFormatter.dateFormat = dayForecastFormat
                    cell.dateLabel.text = dateFormatter.string(from: weatherDate)
                }
                if let weatherIcon = WeatherData.sharedInstance.weatherArray[indexPath.row].weatherIcon {
                    let image = UIImage(named: "\(weatherIcon).png")
                    let templateImage = image?.withRenderingMode(.alwaysTemplate)
                    cell.weatherTypeIcon.image = templateImage
                }
                if let minTemp = WeatherData.sharedInstance.weatherArray[indexPath.row].minTemp {
                    cell.minTempLabel.text = "Min: \(String(format: "%.0f", minTemp))°C"
                }
                if let maxTemp = WeatherData.sharedInstance.weatherArray[indexPath.row].maxTemp {
                    cell.maxTempLabel.text = "Max: \(String(format: "%.0f", maxTemp))°C"
                }
            }
            
        // If hourly forecast
        } else {
            if !WeatherData.sharedInstance.hourlyWeather.isEmpty {
                if let weatherDate = WeatherData.sharedInstance.hourlyWeather[indexPath.row].date {
                    dateFormatter.dateFormat = hourlyForecastFormat
                    cell.dateLabel.text = dateFormatter.string(from: weatherDate)
                }
                if let weatherIcon = WeatherData.sharedInstance.hourlyWeather[indexPath.row].weatherIcon {
                    let image = UIImage(named: "\(weatherIcon).png")
                    let templateImage = image?.withRenderingMode(.alwaysTemplate)
                    cell.weatherTypeIcon.image = templateImage
                }
                if let maxTemp = WeatherData.sharedInstance.hourlyWeather[indexPath.row].temp {
                    cell.maxTempLabel.text = "Max: \(String(format: "%.0f", maxTemp))°C"
                }

                
            }
        }
        return cell
    }
    
    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = weatherCollectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.lightGray.cgColor
        cell?.layer.borderWidth = 3.0
        if !shareWeatherButton.isEnabled {
            shareWeatherButton.isEnabled = true
        }
        textToSpeech(index: indexPath, hourly: WeatherData.sharedInstance.hourlyForecast)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = weatherCollectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.clear.cgColor
        cell?.layer.borderWidth = 0.0
    }
    
    // Collection view format/style
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
    
    // Share action
    @IBAction func shareWeatherAction(_ sender: UIBarButtonItem) {
        dateFormatter.dateFormat = dayForecastFormat
        if let weatherDate = WeatherData.sharedInstance.weatherArray[(selectedIndex?.row)!].date {
            if let weatherDesc = WeatherData.sharedInstance.weatherArray[(selectedIndex?.row)!].weatherDescription {
                let stringToShareArray = [dateFormatter.string(from: weatherDate), weatherDesc]
                let activityVC = UIActivityViewController(activityItems: stringToShareArray, applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = view
                self.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    // Convert collection view cell text to speech
    func textToSpeech(index: IndexPath, hourly: Bool) {
        var textToSpeak = ""
        if !hourly {
            dateFormatter.dateFormat = dayForecastFormat
            if let weatherDate = WeatherData.sharedInstance.weatherArray[index.row].date {
                if let weatherDesc = WeatherData.sharedInstance.weatherArray[index.row].weatherDescription {
                    textToSpeak = "\(dateFormatter.string(from: weatherDate)) \(weatherDesc). Highs of\(String(format: "%.0f", WeatherData.sharedInstance.weatherArray[index.row].maxTemp!)) degrees celsius and lows of \(String(format: "%.0f", WeatherData.sharedInstance.weatherArray[index.row].minTemp!)) degrees celsius."
                }
            }
        }else {
            dateFormatter.dateFormat = hourlyForecastFormat
            if let weatherDate = WeatherData.sharedInstance.hourlyWeather[index.row].date {
                if let weatherDesc = WeatherData.sharedInstance.hourlyWeather[index.row].weatherDescription {
                    textToSpeak = "\(dateFormatter.string(from: weatherDate)) \(weatherDesc). High of\(String(format: "%.0f", WeatherData.sharedInstance.hourlyWeather[index.row].temp!)) degrees celsius."
                }
            }
        }
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.voice = AVSpeechSynthesisVoice(language: WeatherData.sharedInstance.voiceLocale)
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        selectedIndex = index
    }
    
    func audioToMainSpeaker() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
