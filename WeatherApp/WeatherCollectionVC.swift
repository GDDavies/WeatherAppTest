//
//  WeatherCollectionVC.swift
//  WeatherApp
//
//  Created by George Davies on 25/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import UIKit
import CoreLocation

private let reuseIdentifier = "DayCell"

class WeatherCollectionVC: UICollectionViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
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
        print("Latitude: \(location.coordinate.latitude)")
        print("Longitude: \(location.coordinate.longitude)")
        print("Locality: \(placemark.locality!). Postal Code: \(placemark.postalCode!), Administrative Area: \(placemark.administrativeArea!), Country: \(placemark.country!)")
        let locationLatitude = location.coordinate.latitude
        let locationLongitude = location.coordinate.longitude
        //if let encodedString = locationLatitude.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            //getWeatherData(urlString: "http://api.openweathermap.org/data/2.5/weather?q=\(encodedString)&appid=ff3516b24bf01703355151a3ba0addc9")
        print(locationLatitude)
        print(locationLongitude)
            getWeatherData(urlString: "api.openweathermap.org/data/2.5/forecast/daily?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&cnt=10&appid=ff3516b24bf01703355151a3ba0addc9")
        //}

    }
    
    func getWeatherData(urlString: String) {
        let url = URL(string: urlString)
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            DispatchQueue.main.async(execute: {
                print(data)
                //self.setLabel(weatherData: data!)
            })
        }
        
        task.resume()
        
    }
    
    func setLabel(weatherData: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: weatherData, options: []) as! Dictionary<String, AnyObject>
            
            if let main = json["main"] as? Dictionary<String, AnyObject> {
                if let temp = main["temp"] as? Double {
                    print(String(format: "%.1f", temp))
                }
            }
        } catch {
            print("Error fetching data")
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

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
        return cell
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
