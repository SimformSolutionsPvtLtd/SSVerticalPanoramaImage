//
//  ViewController.swift
//  SSVerticalPanorama
//
//  Created by Purvesh Dodiya on 19/10/22.
//  Copyright © 2022 Simform Solutions Pvt. All rights reserved.
//

import UIKit
import SSVerticalPanoramaImage

class ViewController: UIViewController {

    //MARK: - Action Outlets
    @IBOutlet weak var imageView: UIImageView!
    
    //MARK: - Variables
    var verticalPano: SSVerticalPanorama?
    
    //MARK: View Lifecycle
    override func viewDidLoad() {
        verticalPano = SSVerticalPanorama()
        verticalPano?.delegate = self
        verticalPano?.showPreviewScreen = true
    }

}

//MARK: - Action Outlets
extension ViewController {
    
    @IBAction func onClickOfOpenCam(_ sender: UIButton) {
        guard let navController = navigationController, let verticalPano else { return }
        verticalPano.openSSVerticalPanoramaCam(navController: navController)
    }
    
}

//MARK: - SSVerticalPanoDelegate
extension ViewController: SSVerticalPanoDelegate {
    func onImageCaptured(image: UIImage) {
        imageView.image = image
    }
    
}
