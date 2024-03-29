//
//  SwViewController.swift
//  SSVerticalPanorama
//
//  Created by Purvesh Dodiya on 10/18/22.
//  Copyright © 2021 Simform Solutions Pvt. Ltd. All rights reserved.
//

import UIKit

class PreviewController: UIViewController, UIScrollViewDelegate {
    
    //MARK: - Outlets
    @IBOutlet weak var imageViewOutlet: UIImageView!
    @IBOutlet weak var buttonRetake: UIButton!
    @IBOutlet weak var buttonDone: UIButton!
    
    //MARK: - Variables
    var delegate: PreviewDismissDelegate?
    var finalImage = UIImage()
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.bringSubviewToFront(buttonDone)
        view.bringSubviewToFront(buttonRetake)
        imageViewOutlet.image = finalImage
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
    }
}

//MARK: - Action Outlet
extension PreviewController {
    
    @IBAction func onClickOfRetake(_ sender: UIButton) {
        delegate?.onClickOfRetake()
        self.navigationController?.popViewController(animated: false)
    }
    
    @IBAction func onClickOfDone(_ sender: UIButton) {
        delegate?.onClickOfDoneImage(image: finalImage)
        self.navigationController?.popViewController(animated: false)
    }
    
}
