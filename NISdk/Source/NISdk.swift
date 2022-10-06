//
//  NIPaymentContext.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation
import PassKit
import uSDK

private class NISdkBundleLocator {}

@objc public final class NISdk: NSObject {
    @objc public static let sharedInstance = NISdk()
    var sdkLanguage = "en"
    private var isSDKInitialized = false
    
    private func getConfigParamsForServer() -> UConfigParameters {
        var configParams: UConfigParameters {
            let params = UConfigParameters()
            if self.paymentResponse.paymentLinks?.paymentLink?.ngenEnv() == .PROD {
                return params
            }
            let directoryServer = UDirectoryServer(
                dsid: ChallengeConstants.MC_MTF_DIRECTORY_SERVER_ID, publicKey: ChallengeConstants.MC_MTF_DIRECTORY_SERVER_PUBLIC_KEY,
                keyID: ChallengeConstants.MC_MTF_DIRECTORY_SERVER_KEY_ID, dsCACertificate: ChallengeConstants.MC_MTF_DIRECTORY_SERVER_CERT,
                providerName: Constants.MC_DIRECTORY_SERVER_PROVIDER_NAME, dsLogo: nil)
            params.add(directoryServer)
            return params
        }
        return configParams
    }
    
    private override init() {
        super.init()
        let bundle = getBundle()
        UIFont.RegisterFont(withFilenameString: "OCRA.otf", in: bundle)
        UThreeDS2ServiceImpl.shared().u_initialize(self.getConfigParamsForServer(),  locale: "us", uiCustomization: UUiCustomization()) { error in
            if let error = error {
                #if DEBUG
                print(error.localizedDescription)
                #endif
            } else {
                self.isSDKInitialized = true
                guard let sdkVersion = UThreeDS2ServiceImpl.shared().getSDKVersion() else { return }
                #if DEBUG
                print("SDK Initialized successfully \(sdkVersion)")
                #endif
            }
        }
    }
    
    func getBundle() -> Bundle {
        if let bundle = Bundle(path: "NISdk.bundle") {
            return bundle
        } else if let path = Bundle(for: NISdkBundleLocator.self).path(forResource: "NISdk", ofType: "bundle"),
                  let bundle = Bundle(path: path)  {
            return bundle
        } else {
            let bundle = Bundle(for: NISdkBundleLocator.self)
            return bundle
        }
    }
    
    func getBundleFor(language: String) -> Bundle {
        let sdkResourceBundle = getBundle()
        if let languageFilePath = sdkResourceBundle.path(forResource: language, ofType: "lproj") {
            if let languageFile = Bundle(path: languageFilePath) {
                return languageFile
            }
        }
        return sdkResourceBundle
    }
    
    @objc public func deviceSupportsApplePay() -> Bool {
        return PKPaymentAuthorizationViewController.canMakePayments()
    }
    
    @objc public func setSDKLanguage(language: String) {
        sdkLanguage = language
        let direction = Locale.characterDirection(forLanguage: language)
        if (direction == .rightToLeft) {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
        } else {
            UIView.appearance().semanticContentAttribute = .forceLeftToRight
        }
    }
    
    @objc public func showCardPaymentViewWith(cardPaymentDelegate: CardPaymentDelegate,
                                              overParent parentViewController: UIViewController,
                                              for order: OrderResponse) {
        let paymentViewController = PaymentViewController(order: order, cardPaymentDelegate: cardPaymentDelegate,
                                                          applePayDelegate: nil, paymentMedium: .Card)
        let navController = UINavigationController(rootViewController: paymentViewController)
        
        paymentViewController.view.backgroundColor = .clear
        paymentViewController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            paymentViewController.isModalInPresentation = true
        }
        parentViewController.present(navController, animated: true)
    }
    
    @objc public func initiateApplePayWith(applePayDelegate: ApplePayDelegate?,
                                           cardPaymentDelegate: CardPaymentDelegate,
                                           overParent parentViewController: UIViewController,
                                           for order: OrderResponse,
                                           with applePayRequest: PKPaymentRequest) {
        
        let paymentViewController = PaymentViewController(order: order, cardPaymentDelegate: cardPaymentDelegate,
                                                          applePayDelegate: applePayDelegate, paymentMedium: .ApplePay)
        paymentViewController.applePayRequest = applePayRequest
        paymentViewController.view.backgroundColor = .clear
        paymentViewController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            paymentViewController.isModalInPresentation = true
        }
        parentViewController.present(paymentViewController, animated: true)
    }
}
