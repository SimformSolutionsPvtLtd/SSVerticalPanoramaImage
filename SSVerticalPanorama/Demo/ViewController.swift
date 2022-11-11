//
//  ViewController.swift
//  SSVerticalPanorama
//
//  Created by Purvesh Dodiya on 19/10/22.
//  Copyright © 2022 Simform Solutions Pvt. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    //MARK: - Action Outlets
    @IBOutlet weak var imageView: UIImageView!

}

//MARK: - Action Outlets
extension ViewController {
    
    @IBAction func onClickOfOpenCam(_ sender: UIButton) {
        guard let navContrller = navigationController else{ return}
        let verticalPano = SSVerticalPanorama()
        verticalPano.delegate = self
        verticalPano.showPreviewScreen = true
        verticalPano.openSSVerticalPanoramaCam(navController: navContrller)
    }
    
}

//MARK: - SSVerticalPanoDelegate
extension ViewController: SSVerticalPanoDelegate {
    func onImageCaptured(image: UIImage) {
        imageView.image = image
    }
    
}
