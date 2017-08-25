//
//  MapVC.swift
//  WeatherApp
//
//  Created by George Davies on 25/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var location: CLLocation?
    var newLocation: CLLocation?
    var resultSearchController: UISearchController?
    
    @IBAction func mapTypeSegmentedControl(_ sender: UISegmentedControl) {
        switch (sender.selectedSegmentIndex) {
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .satellite
        default:
            mapView.mapType = .hybrid
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let userLocation = location {
            let span = MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegion(center: userLocation.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
        let searchLocationButton = UIBarButtonItem(
            title: "Weather Search",
            style: .plain,
            target: self,
            action: #selector(searchLocationAction(sender:))
        )
        
        self.navigationItem.setRightBarButton(searchLocationButton, animated: true)
        self.navigationController?.title = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchLocationAction(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Search", message: "Search for weather location", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "e.g. London"
        }
        
        alert.addAction(UIAlertAction(title: "Find", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            self.searchForLocation(text: String(describing: (textField?.text)!))
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.dismiss(animated: true, completion: { 
                print("Cancel")
            })
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func searchForLocation(text: String?) {
        if let cityName = text {
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(cityName, completionHandler: { (placemarks, error) -> Void in
                if (placemarks?[0]) != nil {
                    let placemark = placemarks?.first!
                    let location = placemark?.location
                    self.newLocation = CLLocation(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
                }
            })
        }
    }
    
    private func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) {
        
        if let error = error {
            print("Unable to Forward Geocode Address (\(error))")
            print("Unable to Find Location for Address")
            
        } else {
            var location: CLLocation?
            
            if let placemarks = placemarks, placemarks.count > 0 {
                location = placemarks.first?.location
            }
            
            if let location = location {
                let coordinate = location.coordinate
                print("\(coordinate.latitude), \(coordinate.longitude)")
            } else {
                print("No Matching Location Found")
            }
        }
    }
    
    func getWeatherData(urlString: String) {
        let url = URL(string: urlString)
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            DispatchQueue.main.async(execute: {
                self.setLabel(weatherData: data!)
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

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
	}

}
