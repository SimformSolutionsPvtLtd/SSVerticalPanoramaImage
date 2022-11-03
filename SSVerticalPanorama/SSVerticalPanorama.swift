//
//  SSVerticalPanorama.swift
//  SSVerticalPanorama
//
//  Created by Purvesh Dodiya on 19/10/22.
//  Copyright © 2022 Simform Solutions Pvt. All rights reserved.
//

import Foundation
import AVFoundation

class SSVerticalPanorama {
    
    internal var delegate: SSVerticalPanoDelegate?
    internal var showPreviewScreen: Bool = true
    
    func openSSVerticalPanoramaCam(navController: UINavigationController) {
        AVCaptureDevice.requestAccess(for: .video) { success in
            if success {
                // if request is granted (success is true)
                DispatchQueue.main.async {
                    guard let ssCustomeCameraVC = UIStoryboard(name: StoryBoradEnum.ssStoryBoard.rawValue, bundle: nil).instantiateViewController(withIdentifier: ViewContrllerEnum.ssVerticalPanoController.rawValue) as? SSVerticalPanoController else {return}
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
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("close", comment: ""), style: .default, handler: { action in
                alert.dismiss(animated: true)
            }))
            navContrller.present(alert, animated: true)
        }
    }
    
}
