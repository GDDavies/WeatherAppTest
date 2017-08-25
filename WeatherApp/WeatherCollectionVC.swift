//
//  WeatherCollectionVC.swift
//  WeatherApp
//
//  Created by George Davies on 25/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import UIKit
import CoreLocation

class WeatherCollectionVC: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate {

    @IBOutlet weak var weatherCollectionView: UICollectionView!
    @IBOutlet weak var cityNameLabel: UILabel!
    
    // MARK: - Properties
    fileprivate let reuseIdentifier = "DayCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    fileprivate let apiKey = "ff3516b24bf01703355151a3ba0addc9"
    fileprivate let itemsPerRow: CGFloat = 2
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate var weatherArray = [DayWeather]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //weatherCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        findLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
//        print("Latitude: \(location.coordinate.latitude)")
//        print("Longitude: \(location.coordinate.longitude)")
//        print("Locality: \(placemark.locality!). Postal Code: \(placemark.postalCode!), Administrative Area: \(placemark.administrativeArea!), Country: \(placemark.country!)")

        getWeatherData(urlString: "http://api.openweathermap.org/data/2.5/forecast/daily?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&cnt=10&appid=\(apiKey)")
    }
    
    func getWeatherData(urlString: String) {
        let url = URL(string: urlString)
        
        let task = URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            DispatchQueue.main.async(execute: {
                if let unwrappedData = data {
                    // If successful pass data object to json variable as dictionary
                    do {
                        self.convertForecastJSON(weatherData: unwrappedData)
                    } catch {
                        // Error popup
                        print("Error fetching data")
                    }
                } else {
                    // Error popup
                    print("Unable to retrieve data")
                }
            })
        })
        task.resume()
    }
    
    func convertForecastJSON(weatherData: Data) {
        if weatherArray.isEmpty {
            do {
                let json = try JSONSerialization.jsonObject(with: weatherData, options: []) as! Dictionary<String, AnyObject>
                
                var city: String?
                
                if let cityData = json["city"] as? Dictionary<String, AnyObject> {
                    if let cityName = cityData["name"] as? String {
                        city = cityName
                        cityNameLabel.text = city
                    }
                }
                if let forecastData = json["list"] as? [Dictionary<String, AnyObject>] {
                    for forecast in forecastData {
                        let weatherForecast = DayWeather()
                        weatherForecast.city = city

                        let epochTime = forecast["dt"] as? Int
                        let date = Date(timeIntervalSince1970: TimeInterval(epochTime!))
                        weatherForecast.date = date
                        if let temperatures = forecast["temp"] as? Dictionary<String, AnyObject> {
                            weatherForecast.minTemp = temperatures["min"] as? Double
                            weatherForecast.maxTemp = temperatures["max"] as? Double
                        }
                        if let weather = forecast["weather"] as? [Dictionary<String, AnyObject>] {
                            weatherForecast.weatherId = weather[0]["id"] as? Int
                            weatherForecast.weatherMain = weather[0]["main"] as? String
                            weatherForecast.weatherDescription = weather[0]["description"] as? String
                            weatherForecast.weatherIcon = weather[0]["icon"] as? String
                        }
                        weatherArray.append(weatherForecast)
                    }
                }
                weatherCollectionView.reloadData()
            } catch {
                print("Error fetching data")
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return weatherArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! WeatherCollectionViewCell
        cell.backgroundColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)
        
        if !weatherArray.isEmpty {
            if let weatherDate = weatherArray[indexPath.row].date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d MMM"
                cell.dateLabel.text = dateFormatter.string(from: weatherDate)
                
            }
            if let weatherIcon = weatherArray[indexPath.row].weatherIcon {
                let image = UIImage(named: "\(weatherIcon).png")
                let templateImage = image?.withRenderingMode(.alwaysTemplate)
                cell.weatherTypeIcon.image = templateImage
                cell.weatherTypeIcon.tintColor = UIColor.white
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
