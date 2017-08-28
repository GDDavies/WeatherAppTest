//
//  WeatherDataManager.swift
//  WeatherApp
//
//  Created by George Davies on 25/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import Foundation
import CoreLocation

let weatherDataNCKey = "com.georgeddavies.weatherData"
let hourlyDataNCKey = "com.georgeddavies.hourlyData"

class WeatherData: NSObject {
    
    static let sharedInstance = WeatherData()
    var weatherArray = [DayWeather]()
    var hourlyWeather = [HourWeather]()
    var daysCount = 10
    var voiceLocale = "en-GB"
    var city = "London, UK"
    var hourlyForecast = false
    
    fileprivate let apiKey = "ff3516b24bf01703355151a3ba0addc9"
    
    func getWeatherData(latitude: Double, longitude: Double) {
        
        getLocaleAndDaysToForecast()
        
        let url = URL(string: "http://api.openweathermap.org/data/2.5/forecast/daily?lat=\(latitude)&lon=\(longitude)&cnt=\(String(describing: daysCount))&appid=\(apiKey)")
        
        let task = URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            DispatchQueue.main.async(execute: {
                if let unwrappedData = data {
                    // If successful pass data object to json variable as dictionary
                    self.convertForecastJSON(weatherData: unwrappedData)
                } else {
                    // Error popup
                    print("Unable to retrieve data")
                }
            })
        })
        task.resume()
    }
    
    func convertForecastJSON(weatherData: Data) {
        weatherArray.removeAll()
        do {
            let json = try JSONSerialization.jsonObject(with: weatherData, options: []) as! Dictionary<String, AnyObject>
            
            if let cityData = json["city"] as? Dictionary<String, AnyObject> {
                if let cityName = cityData["name"] as? String {
                    city = cityName
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
                        weatherForecast.minTemp = (temperatures["min"] as? Double)! - 273.15
                        weatherForecast.maxTemp = (temperatures["max"] as? Double)! - 273.15
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
        } catch {
            print("Error fetching data")
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: weatherDataNCKey), object: self)
    }
    
    func getLocaleAndDaysToForecast() {
        for element in UserDefaults.standard.dictionaryRepresentation() {
            if element.key == "Users" {
                for user in element.value as! Array<[String:Any]> {
                    if user["isSelected"] as? Bool == true {
                        voiceLocale = user["locale"] as! String
                        daysCount = user["daysToForecast"] as! Int
                        hourlyForecast = user["hourlyForecast"] as! Bool
                    }
                }
            }
        }
    }
    
    func getHourlyForecast(latitude: Double, longitude: Double) {
                
        let url = URL(string: "http://api.openweathermap.org/data/2.5/forecast?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)")
        
        let task = URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            DispatchQueue.main.async(execute: {
                if let unwrappedData = data {
                    // If successful pass data object to json variable as dictionary
                    self.convertHourlyForecast(weatherData: unwrappedData)
                } else {
                    // Error popup
                    print("Unable to retrieve data")
                }
            })
        })
        task.resume()
    }
    
    func convertHourlyForecast(weatherData: Data) {
        hourlyWeather.removeAll()
        do {
            let json = try JSONSerialization.jsonObject(with: weatherData, options: []) as! Dictionary<String, AnyObject>
            
            if let forecastData = json["list"] as? [Dictionary<String, AnyObject>] {
                for forecast in forecastData {
                    let hourlyForecastData = HourWeather()
                    hourlyForecastData.city = city
                    
                    let epochTime = forecast["dt"] as? Int
                    let date = Date(timeIntervalSince1970: TimeInterval(epochTime!))
                    hourlyForecastData.date = date
                    print(date)
                    if let temperatures = forecast["main"] as? Dictionary<String, AnyObject> {
                        hourlyForecastData.temp = (temperatures["temp_max"] as? Double)! - 273.15
                    }
                    if let weather = forecast["weather"] as? [Dictionary<String, AnyObject>] {
                        hourlyForecastData.weatherId = weather[0]["id"] as? Int
                        hourlyForecastData.weatherMain = weather[0]["main"] as? String
                        hourlyForecastData.weatherDescription = weather[0]["description"] as? String
                        hourlyForecastData.weatherIcon = weather[0]["icon"] as? String
                    }
                    hourlyWeather.append(hourlyForecastData)
                }
            }
        } catch {
            print("Error fetching data")
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: hourlyDataNCKey), object: self)
    }
}
