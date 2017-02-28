//
//  H2OPalIntegrationViewController.swift
//  H2OPal Demo App
//
//  Created by Matic Kunaver on 19/02/2017.
//  Copyright © 2017 Out of Galaxy, Inc. All rights reserved.
//

import UIKit

class H2OPalIntegrationsViewController: UIViewController {

  var deepLinkPayload: [String : Any]?

  static func presentModaly(deepLinkPayload: [String : Any]? = nil) {
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let viewController = mainStoryboard.instantiateViewController(withIdentifier: "H2OPalIntegrationsViewController") as! H2OPalIntegrationsViewController
    viewController.deepLinkPayload = deepLinkPayload

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    appDelegate.window?.rootViewController?.present(viewController, animated: true, completion: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if let deepLinkPayload = deepLinkPayload,
      let authenticationCode = deepLinkPayload["authorization_code"] as? String {
      H2OPalBackendHandler.h2opalAuthenticate(authenticationCode: authenticationCode, completion: { (error) in
        if let error = error {
          self.presentAlertWithTitle(NSLocalizedString("Could not link this app to H2OPal app", comment: ""), text: error.localizedDescription, handler: { (alertAction) in
            self.dismiss(animated: true, completion: nil)
          })
        }
      })
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}

extension UIViewController {
  func presentAlertWithTitle(_ title : String, text: String, handler: ((UIAlertAction) -> Swift.Void)? = nil) {
    let alertController = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)

    let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.cancel, handler: handler)

    alertController.addAction(action)

    present(alertController, animated: true, completion: nil)
  }
}
