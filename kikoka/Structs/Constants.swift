//
//  Constants.swift.swift
//  kikoka
//
//  Created by o.yuki on 2021/11/27.
//

import Foundation

struct Constants {
    static let shared = Constants()
    private init() {}
    
    let baseUrl = "https://kikoka.herokuapp.com/api"
    let service = "com.oyuki.kikoka"
}
