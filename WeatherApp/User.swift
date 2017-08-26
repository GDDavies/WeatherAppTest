//
//  User.swift
//  WeatherApp
//
//  Created by George Davies on 26/08/2017.
//  Copyright © 2017 George Davies. All rights reserved.
//

import Foundation

@objc(User)
class User: NSObject, NSCoding{
    
    var userName: String?
    var daysToForecast: Int?
    var locale: String?
    
    init(userName: String, daysToForecast: Int, locale: String) {
        self.userName = userName
        self.daysToForecast = daysToForecast
        self.locale = locale
    }
    
    required init(coder decoder: NSCoder) {
        self.userName = decoder.decodeObject(forKey: "userName") as? String ?? ""
        self.daysToForecast = decoder.decodeInteger(forKey: "daysToForecast")
        self.locale = decoder.decodeObject(forKey: "locale") as? String ?? ""
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(userName, forKey: "userName")
        coder.encode(daysToForecast, forKey: "daysToForecast")
        coder.encode(locale, forKey: "locale")
    }
    
}
