# Sample code - H2OPal integration
This is a sample code for integrating 3rd party app with H2OPal service

Your app is responsible for authenticating user and providing credentials to your backend service. 

See sample code (and use it freely in your app) for additional help. 

####Important
If your app does not have registered URL scheme, register it in your app (documentation is available on [Apple's developer portal](https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html)).

##Authentication
Before your app or backend can query H2OPal's water entries, you must get unique user identifier and token.  To do that,  call H2OPal's deep link. H2OPal app will reopen your app via regiesterd URL scheme. Invocation deep link will hold required information so you can continue with authentication.

1. Prepare deep link:

```swift
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
  ```
  
2. Invoke prepared deep link via 'func openURL(_ url: URL) -> Bool'
  
  ```swift
  if let url = H2OPalBackendHandler.authenticationDeepLink {
      UIApplication.shared.openURL(url)
    }
  ```
  
3. Wait for callback from H2OPal app (implement this in you AppDelegate):
  
    ```swift
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

    if let payload = H2OPalBackendHandler.handleAuthorizeAction(url: url) {
      // Send this back to your Backend

      return true
    }

    return false
  }
 
 ```
 
4. Parse deep link and send authentication data to H2OPal's servers:
 
 ```swift
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
  ```
 
 After you have completed these steps, your app (and your backend) is authenticated to use H2OPal's water intake data. 
 
 
 # Sample code - H2OPal Shopify integration
This is a sample code for integrating Shopify store in your app.

1. Obtain credentials for Shopify SDK from Out of Galaxy Inc. Generate new, unqique merhant id for Apple Pay.  ([Apple Pay Guide](https://developer.apple.com/library/content/ApplePay_Guide/Configuration.html))

2. Integrate shopify SDK.

3. Drag and drop source code from `Shop` group in H2OPal Demo Xcode project to your project.

4. Present Store by Using `StoreHandler` class. Example code 


```swift
  @IBAction func buyButtonPressed(_ sender: Any) {
    let storeHandler = StoreHandler(viewController: self)
    storeHandler.presentProductViewController(6567040517)
  }
  

  
  

