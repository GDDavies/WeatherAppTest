//
//  MapViewVC.swift
//  WeatherApp
//
//  Created by George Davies on 25/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Speech


class MapViewVC: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var segmentedControlOutlet: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView!
    
    var location: CLLocation?
    var newLocation: CLLocation?
    var newCityName: String?
    var resultSearchController: UISearchController?
    
    let audioEngine = AVAudioEngine()
    
    var backgroundView = UIView()
    var dialogueView = UIView()
    
    @IBOutlet weak var siriButton: UIBarButtonItem!
    
    // MARK: - Version check
    // Only enable Siri search in iOS 10+
    var speechRecogniser: Any? = {
        if #available(iOS 10.0, *) {
            return SFSpeechRecognizer()
        } else {
            return false
        }
    }()
    
    var request: Any? = {
        if #available(iOS 10.0, *) {
            return SFSpeechAudioBufferRecognitionRequest()
        } else {
            return false
        }
    }()
    
    var recognitionTask: Any? = {
        if #available(iOS 10.0, *) {
            return SFSpeechRecognitionTask()
        } else {
            return false
        }
    }()
    
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
    
    @IBAction func mapSearch(_ sender: UIBarButtonItem) {
        searchLocationAction(sender: sender)
    }
        
    @IBAction func activateSiriButton(_ sender: UIBarButtonItem) {
        siriButton.tintColor = UIColor.red
        speechToSearch()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.segmentedControlOutlet.tintColor = themeColour
        if let startLocation = location {
            goToLocationOnMap(location: startLocation)
        }
        requestSpeechAuthorization()
    }

    // MARK: - Location methods
    
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
    
    //MARK: - Check authorization status
    
    func requestSpeechAuthorization() {
        if #available(iOS 10.0, *) {
            SFSpeechRecognizer.requestAuthorization { authStatus in
                OperationQueue.main.addOperation {
                    switch authStatus {
                    case .authorized:
                        self.siriButton.isEnabled = true
                    case .denied:
                        self.siriButton.isEnabled = false
                    case .restricted:
                        self.siriButton.isEnabled = false
                    case .notDetermined:
                        self.siriButton.isEnabled = false
                    }
                }
            }
        } else {
            self.siriButton.isEnabled = false
        }
    }
    
    // MARK: - Siri
    
    func speechToSearch() {
        
        if #available(iOS 10.0, *) {
            
            guard let node = audioEngine.inputNode else { return }
            let recordingFormat = node.outputFormat(forBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                let req = self.request as! SFSpeechAudioBufferRecognitionRequest
                req.append(buffer)
            }
            
            audioEngine.prepare()
            do {
                try audioEngine.start()
            } catch {
                return print(error)
            }
            
            guard let myRecogniser = SFSpeechRecognizer() else {
                // A recogniser is not supported for current locale
                return
            }
            
            if !myRecogniser.isAvailable {
                // A recogniser is not available right now
                return
            }

            recognitionTask = (speechRecogniser as! SFSpeechRecognizer).recognitionTask(with: request as! SFSpeechRecognitionRequest, resultHandler: { result, error in
                if let result = result {
                    let transcribedString = result.bestTranscription.formattedString
                    
                    if transcribedString.components(separatedBy: " ").count == 1 {
                        self.searchForLocation(text: transcribedString)
                        print(transcribedString)
                        self.audioEngine.stop()
                        if let node = self.audioEngine.inputNode {
                            node.removeTap(onBus: 0)
                        }
                        (self.recognitionTask as! SFSpeechRecognitionTask).cancel()
                        self.siriButton.tintColor = themeColour
                    }
                } else if let error = error {
                    print(error)
                }
            })

        } else {
            // Fallback on earlier versions
        }
    }
}
