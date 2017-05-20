//
//  StoreHandler.swift
//  H2OPal
//
//  Created by Matic Kunaver on 20. 09. 15.
//  Copyright © 2015 Makro Plus d.o.o. All rights reserved.
//

import UIKit
import Buy

class StoreHandler: NSObject {

    weak var viewController: UIViewController?

    lazy var client:BUYClient = {
        return BUYClient(shopDomain: "insert shop domain", apiKey: "insert api key", appId: "insert app id")
        }()

    lazy var productViewController: ProductViewController = {
        let theme = Theme()
        theme.style = .light
        theme.tintColor = UIColor(red:0.04, green:0.67, blue:0.85, alpha:1)

        let viewController = ProductViewController(client: self.client, theme: theme)
        viewController?.merchantId = "insert Apple Pay merchant id"

        return viewController!
        }()

    var product: BUYProduct?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    fileprivate func loadProductIfNeededWithIdentifier(_ productID: Double, completion: @escaping (_ product: BUYProduct?, _ error: NSError?) -> Void )
    {
        if let product = self.product {
            completion(product, nil)
            return
        }

      // Present activity indicator

        self.client.getProductById(NSNumber(value: productID)) { (loadedProduct, shopifyError) in

            if loadedProduct != nil {
                self.product = loadedProduct
            }
            else {
              // Present activity indicator

                if let error = shopifyError {
                    self.presentAlertWithTitle(NSLocalizedString("Problem with connection", comment: ""), text: error.localizedDescription)
                }
            }

            completion(self.product, shopifyError as NSError?)
        }

    }

    func presentProductViewController(_ productIdentifier: Double = 6567040517) {
        loadProductIfNeededWithIdentifier(productIdentifier) { (product, error) -> Void in
            if let product = product {

              // Present activity indicator

                self.productViewController .load(with: product, completion: { (success, error) -> Void in
                    self.viewController! .present(self.productViewController, animated: true, completion: {
                          // Hide activity indicator
                    })


                })
            }
        }
    }


    fileprivate func presentAlertWithTitle(_ title : String, text: String) {
        let alertController = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)

        let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.cancel, handler: nil)

        alertController.addAction(action)
        
        viewController!.present(alertController, animated: true, completion: nil)
    }


}



