//
//  Enumaration.swift
//  SSVerticalPanorama
//
//  Created by Purvesh Dodiya on 10/18/22.
//  Copyright © 2021 Simform Solutions Pvt. Ltd. All rights reserved.
//

import Foundation

enum StoryBoradEnum: String {
    case ssStoryBoard = "SSStoryboard"
}

enum ViewContrllerEnum: String {
    case previewController = "previewController"
    case ssVerticalPanoController = "sSVerticalPanoController"
}

enum InstructionEnum: String {
    case stablePosition = "Move iPhone continuously"
    case moveRight = "Move right to center"
    case moveLeft = "Move Left to center"
    case slowDown = "Slow Down"
    case keepArrow = "Keep the arrow on centre line"
}

enum ImageEnum: String {
    case flashOf = "flash_off"
    case flashOn = "flash_on"
}
