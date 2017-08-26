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

class MapViewVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var location: CLLocation?
    var newLocation: CLLocation?
    var newCityName: String?
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
        
        let searchLocationButton = UIBarButtonItem(
            title: "Weather Search",
            style: .plain,
            target: self,
            action: #selector(searchLocationAction(sender:))
        )
        if let startLocation = location {
            goToLocationOnMap(location: startLocation)
        }
        
        self.navigationItem.setRightBarButton(searchLocationButton, animated: true)
        self.navigationController?.title = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goToLocationOnMap(location: CLLocation) {
        var userLocation: CLLocation?
        if newLocation != nil {
            userLocation = newLocation
        } else {
            userLocation = location
        }
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegion(center: (userLocation?.coordinate)!, span: span)
        mapView.setRegion(region, animated: true)
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
                if let err = error {
                    print(err)
                } else if (placemarks?[0]) != nil {
                    let placemark = placemarks?.first!
                    self.newCityName = placemark?.locality
                    self.newLocation = placemark?.location
                    self.goToLocationOnMap(location: self.newLocation!)

                }
            })
        }
    }
    
}
