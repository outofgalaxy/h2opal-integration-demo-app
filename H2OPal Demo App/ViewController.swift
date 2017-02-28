//
//  ViewController.swift
//  H2OPal Demo App
//
//  Created by Matic Kunaver on 18/02/2017.
//  Copyright © 2017 Out of Galaxy, Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func authorizeButtonPressed(_ sender: Any) {
    // Check if H2OPal app is install - if not, take user to the App Store
    guard UIApplication.shared.canOpenURL(URL(string:"h2opal://")!) else {
      UIApplication.shared.openURL(URL(string: "https://itunes.apple.com/us/app/h2opal-stay-hydrated-stay-healthy/id943662323?ls=1&mt=8")!)
      return
    }

    if let url = H2OPalBackendHandler.authenticationDeepLink {
      UIApplication.shared.openURL(url)
    }
  }
}

