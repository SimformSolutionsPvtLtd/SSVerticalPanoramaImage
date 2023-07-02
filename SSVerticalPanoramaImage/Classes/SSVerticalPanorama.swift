//
//  SSVerticalPanorama.swift
//  SSVerticalPanorama
//
//  Created by Purvesh Dodiya on 19/10/22.
//  Copyright © 2022 Simform Solutions Pvt. All rights reserved.
//

import Foundation
import AVFoundation

public class SSVerticalPanorama {
    
    public var delegate: SSVerticalPanoDelegate?
    public var showPreviewScreen: Bool = true
    
    public init() {
        
    }
    
    public func openSSVerticalPanoramaCam(navController: UINavigationController) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] success in
            guard let self else { return }
            if success {
                // if request is granted (success is true)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    let bundle = Bundle(for: Self.self)
                    let storyboard = UIStoryboard(name: StoryBoradEnum.ssStoryBoard.rawValue, bundle: bundle)
                    guard let ssCustomeCameraVC = storyboard.instantiateViewController(withIdentifier: ViewContrllerEnum.ssVerticalPanoController.rawValue) as? SSVerticalPanoController else {return}
                    ssCustomeCameraVC.delegate = self.delegate
                    ssCustomeCameraVC.showPreviewScreen = self.showPreviewScreen
                    navController.pushViewController(ssCustomeCameraVC, animated: true)
                }
               
            } else {
                // if request is denied (success is false)
                self.showAlertForCameraPermission(navContrller: navController)
            }
        }
    }
    
    private func showAlertForCameraPermission(navContrller: UINavigationController) {
        // Create Alert
        DispatchQueue.main.async {
            let alert = UIAlertController(title: NSLocalizedString("camera", comment: ""), message: NSLocalizedString("cameraPermissionMessage", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("openSetting", comment: ""), style: .default, handler: { action in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("close", comment: ""), style: .default, handler: { action in
                alert.dismiss(animated: true, completion: nil)
            }))
            
            if let navController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                navController.present(alert, animated: true, completion: nil)
            }
        }

    }
}
