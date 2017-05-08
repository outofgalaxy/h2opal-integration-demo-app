//
//  H2OPalBackendHandler.swift
//  H2OPal Demo App
//
//  Created by Matic Kunaver on 18/02/2017.
//  Copyright © 2017 Out of Galaxy, Inc. All rights reserved.
//

import Foundation

class H2OPalBackendHandler {
  struct Constants {
    static let applicationID = "5750826253418496"
    static let applicationSecret = "160f0c53-ce0c-4bf0-81dd-d309812a2078"
    static let requiredScopes = ["profile_read", "water_entries_read", "water_entries_webhook"]
    static let redirectURL = "app://h2opal"
  }

  static private func hmacSignature(timestamp: String, payload: String, requestBody: String? = nil) -> String {
    var text = Constants.applicationID + payload + timestamp
    if let body = requestBody {
      text = text + body
    }
    return text.hmac(algorithm: .SHA256, key: Constants.applicationSecret)
  }

  //h2opal://authorize?application_id=5750826253418496&scopes=profile_read%20water_entries_read%20water_entries_webhook&redirect_url=app%3A%2F%2Fh2opal&timestamp=1487265652000&hmac=7664a8412adea042a7e981259e45ba0abd7e8aebc0ae88f01c382f3ed9b25831
  static public var authenticationDeepLink: URL? {
    var components = URLComponents()
    components.scheme = "h2opal" // H2OPal app url scheme
    components.host = "authorize"

    // Current timestamp in miliseconds
    let timestamp = String(format: "%.0f", Date().timeIntervalSince1970 * 1000)

    // Params
    let applicationIDQuery = URLQueryItem(name: "application_id", value: Constants.applicationID)
    let scopesQuery = URLQueryItem(name: "scopes", value: Constants.requiredScopes.joined(separator: " "))
    let redirectURLQuery = URLQueryItem(name: "redirect_url", value: Constants.redirectURL)
    let timestampQuery = URLQueryItem(name: "timestamp", value: timestamp)
    let hmacSignatureQuery = URLQueryItem(name: "hmac", value: hmacSignature(timestamp: timestamp, payload: Constants.redirectURL))
    components.queryItems = [applicationIDQuery, scopesQuery, redirectURLQuery, timestampQuery, hmacSignatureQuery]

    return components.url
  }

  public static func handleAuthorizeAction(url: URL) -> [String : Any]? {
    guard let queryItems = url.queryItems else {
      return nil
    }

    // Map query items to custom hashmap
    var payload = [String: Any]()
    if let authorizationCode = queryItems["authorization_code"] {
      payload["authorization_code"] = authorizationCode
    }

    return payload
  }

  // H2OPal backend
  static private var urlComponents: URLComponents { // base URL components of the web service
    var components = URLComponents()
    components.scheme = "https"
    components.host = "api.h2opal.com"

    return components
  }
  static private let session = URLSession(configuration: .default)

  static func h2opalAuthenticate(authenticationCode: String, completion: @escaping (NSError?) -> Void) {
    var authenticateURLComponents = urlComponents
    authenticateURLComponents.path = "/application/v1/token"

    let timestamp = String(format: "%.0f", Date().timeIntervalSince1970 * 1000)

    let timestampQuery = URLQueryItem(name: "timestamp", value: timestamp)
    let hmacSignatureQuery = URLQueryItem(name: "hmac", value: hmacSignature(timestamp: timestamp, payload: authenticationCode))
    let applicationIDQuery = URLQueryItem(name: "application_id", value: Constants.applicationID)
    let authenticationCodeQuery = URLQueryItem(name: "code", value: authenticationCode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed))
    authenticateURLComponents.queryItems = [applicationIDQuery, timestampQuery, hmacSignatureQuery, authenticationCodeQuery]

    let authenticateURL = authenticateURLComponents.url!

    session.dataTask(with: authenticateURL) { (data, response, error) in
      if let data = data,
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        if  let token = json?["token"] as? String,
          let userID = json?["user_id"] as? String
        {
          // Store credentials somewhere (UserDefaults, CoreData, Database, etc)
          // and use them from now on (or send them to your server)
          UserDefaults.standard.set(token, forKey: "h2opal_token")
          UserDefaults.standard.set(userID, forKey: "h2opal_user_id")
          UserDefaults.standard.synchronize()

        } else if let errorMessage = json?["error_message"] as? String,
          let errorCode = json?["error_code"] as? Int {
          // Handle error
          let error = NSError(domain: "com.myapp.error.backend", code: errorCode, userInfo: [NSLocalizedDescriptionKey : errorMessage])
          completion(error)
        }
      }
      }.resume()
  }

  // Example usage
  static func h2opalLoadWaterEntriesForDates(startDate: Date, completion: @escaping (NSError?) -> Void) {
    guard let userID = UserDefaults.standard.object(forKey: "h2opal_user_id") as? String,
      let token = UserDefaults.standard.object(forKey: "h2opal_token") as? String else {
        return
    }

    var authenticateURLComponents = urlComponents
    authenticateURLComponents.path = "/application/v1/user/\(userID)/daily_goals"

    let timestamp = String(format: "%.0f", Date().timeIntervalSince1970 * 1000)

    let queryDate = String(format: "%.0f", startDate.timeIntervalSince1970 * 1000)
    let body = ["dayTimestamps" : [queryDate]]

    var bodyData: Data?
    do {
      bodyData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
    }
    catch {
      debugPrint("Cannot serialize JSON body")
    }

    let timestampQuery = URLQueryItem(name: "timestamp", value: timestamp)
    let hmacSignatureQuery = URLQueryItem(name: "hmac", value: hmacSignature(timestamp: timestamp, payload: token, requestBody: String(data: bodyData!, encoding: .utf8)!))
    let applicationIDQuery = URLQueryItem(name: "application_id", value: Constants.applicationID)
    authenticateURLComponents.queryItems = [applicationIDQuery, timestampQuery, hmacSignatureQuery]

    let authenticateURL = authenticateURLComponents.url!

    var urlRequest = URLRequest(url: authenticateURL)
    urlRequest.httpBody = bodyData
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    session.dataTask(with: urlRequest) { (data, response, error) in
      if let data = data,
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        if  let dailyGoals = json?["list"] as? [Any]
        {
          // Do something with dailyGoals
          print(dailyGoals.count)

        } else if let errorMessage = json?["error_message"] as? String,
          let errorCode = json?["error_code"] as? Int {
          // Handle error
          let error = NSError(domain: "com.myapp.error.backend", code: errorCode, userInfo: [NSLocalizedDescriptionKey : errorMessage])
          completion(error)
        }
      }
      }.resume()
  }

  static func h2opalLoadWaterEntries(completion: @escaping (NSError?) -> Void) {
    guard let userID = UserDefaults.standard.object(forKey: "h2opal_user_id") as? String,
      let token = UserDefaults.standard.object(forKey: "h2opal_token") as? String else {
        return
    }

    var authenticateURLComponents = urlComponents
    authenticateURLComponents.path = "/application/v1/user/\(userID)/daily_goals"

    // 1: Send 0 for timestamp if this is your first time querying the server, otherwise use timestamp retreived from the server. See comment no.: 5
    let previousSyncUTCTimeStamp =  UserDefaults.standard.object(forKey: "latestTimestampFromServer") as? Double ?? 0
    let body = ["previousSyncUTCTimestamp" : previousSyncUTCTimeStamp]

    var bodyData: Data?
    do {
      bodyData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
    }
    catch {
      debugPrint("Cannot serialize JSON body")
    }

    let timestamp = String(format: "%.0f", Date().timeIntervalSince1970 * 1000)
    let timestampQuery = URLQueryItem(name: "timestamp", value: timestamp)
    let hmacSignatureQuery = URLQueryItem(name: "hmac", value: hmacSignature(timestamp: timestamp, payload: token, requestBody: String(data: bodyData!, encoding: .utf8)!))
    let applicationIDQuery = URLQueryItem(name: "application_id", value: Constants.applicationID)
    authenticateURLComponents.queryItems = [applicationIDQuery, timestampQuery, hmacSignatureQuery]

    let authenticateURL = authenticateURLComponents.url!

    var urlRequest = URLRequest(url: authenticateURL)
    urlRequest.httpBody = bodyData
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    session.dataTask(with: urlRequest) { (data, response, error) in
      if let data = data,
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        if  let dailyGoals = json?["list"] as? [[String : Any]]
        {
          // 2: Do something with dailyGoals
          print(dailyGoals.count)

          // 3: Sort daily goals "updated" keys - ascending and take last
          var updatedTimes = dailyGoals.flatMap({ (element) -> Double? in
            return element["updated"] as? Double
          })

          // 4: Take last timestamp
          updatedTimes = updatedTimes.sorted()

          // 5: Save it somewhere so you can use it later when querying server for new entries. See comment no.: 1
          if let latestTimestamp = updatedTimes.last {
            UserDefaults.standard.set(latestTimestamp, forKey: "latestTimestampFromServer")
            UserDefaults.standard.synchronize()
          }

        } else if let errorMessage = json?["error_message"] as? String,
          let errorCode = json?["error_code"] as? Int {
          // Handle error
          let error = NSError(domain: "com.myapp.error.backend", code: errorCode, userInfo: [NSLocalizedDescriptionKey : errorMessage])
          completion(error)
        }
      }
      }.resume()
  }
}

extension URL {
  var queryItems: [String: String]? {
    var params = [String: String]()
    return URLComponents(url: self, resolvingAgainstBaseURL: false)?
      .queryItems?
      .reduce([:], { (_, item) -> [String: String] in
        params[item.name] = item.value
        return params
      })
  }
}
