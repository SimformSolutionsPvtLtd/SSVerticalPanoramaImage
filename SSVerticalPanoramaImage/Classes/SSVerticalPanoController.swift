//
//  CustomCameraController.swift
//  SSVerticalPanorama
//
//  Created by Purvesh Dodiya on 10/18/22.
//  Copyright © 2021 Simform Solutions Pvt. Ltd. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

public protocol PreviewDismissDelegate {
    func onClickOfDoneImage(image: UIImage)
    func onClickOfRetake()
}

public protocol SSVerticalPanoDelegate {
    func onImageCaptured(image: UIImage)
}

class SSVerticalPanoController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var buttonTakePhoto:UIButton!
    @IBOutlet weak var viewCenter: UIView!
    @IBOutlet weak var viewCenterLine: UIView!
    @IBOutlet weak var imageArrow: UIImageView!
    @IBOutlet weak var constraintArrowXAlign: NSLayoutConstraint!
    @IBOutlet weak var constraintArrowTop: NSLayoutConstraint!
    @IBOutlet weak var viewCamera: UIView!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var viewActivityIndicator: UIView!
    @IBOutlet weak var buttonClose: UIButton!
    @IBOutlet weak var buttonsFlash: UIButton!
    @IBOutlet weak var buttonZoomIn: UIButton!
    @IBOutlet weak var lblInstruction: UILabel!
    @IBOutlet weak var buttonZoomOut: UIButton!
    @IBOutlet weak var viewInstruction: UIView!
    @IBOutlet weak var constraintPreviewBottom: NSLayoutConstraint!
    @IBOutlet weak var constraintPreviewTop: NSLayoutConstraint!
    
    //MARK: - Variables
    private var currentDevice: AVCaptureDevice? = nil
    private var avCameraImageOutput: AVCapturePhotoOutput? = nil
    private var avCameraImageArray: [UIImage] = []
    private var motionManager: CMMotionManager?
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private let captureSession = AVCaptureSession()
    private var partialCapturedDistance = Constants.zeroDouble
    private var isCameraStarted = false
    private var needToTakeImage = true
    private var horizontalDistance = Constants.zeroDouble
    private var stitchingTask: Task<(), Never>?
    private var finalImage: UIImage? = nil
    private var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    private var arrayOfSpeed: [Double] = []
    private var verticalArrowDistance = Constants.initialVerticalDistance {
        didSet {
            updateTopConstraint()
        }
    }
    private var isTopToBottomDirection = true {
        didSet {
            updateTopConstraint()
        }
    }
    var delegate: SSVerticalPanoDelegate?
    var showPreviewScreen: Bool = true
    
    // Customize icons
    var closeImage: UIImage? = nil
    var flashImage: UIImage? = nil
    var zoomInImage: UIImage? = nil
    var zoomOutImage: UIImage? = nil
    var startCameraImage: UIImage? = nil
    var stopCameraImage: UIImage? = nil
    var arrowImage: UIImage? = nil
    
    //MARK: - ViewLife Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        showProgressBar(show: false)
        configureSession()
        initialSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
    }
    
}

//MARK: - Initial Setup
extension SSVerticalPanoController {
    func initialSetup() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(performCenterViewAction))
        viewCenter.addGestureRecognizer(tapGesture)
        lblInstruction.numberOfLines = .zero
        self.lblInstruction.text = InstructionEnum.stablePosition.rawValue
        imagePreview.transform = CGAffineTransform(rotationAngle: .pi / 2)
        
        if let closeImage {
            buttonClose.setImage(closeImage, for: .normal)
        }
        if let flashImage {
            buttonsFlash.setImage(flashImage, for: .normal)
        }
        if let zoomInImage {
            buttonZoomIn.setImage(zoomInImage, for: .normal)
        }
        if let zoomOutImage {
            buttonZoomOut.setImage(zoomOutImage, for: .normal)
        }
        if let startCameraImage {
            buttonTakePhoto.setImage(startCameraImage, for: .normal)
        }
        if let stopCameraImage {
            buttonTakePhoto.setImage(stopCameraImage, for: .selected)
        }
        if let arrowImage {
            imageArrow.image = arrowImage
        }
        
    }
}

// MARK: - Action methods
extension SSVerticalPanoController {
    
    @IBAction func onClickOfCamera(sender: UIButton) {
        UIView.transition(with: sender, duration: Constants.halfDouble, options: .transitionFlipFromTop, animations: {
            self.buttonTakePhoto.isSelected = !sender.isSelected
        },completion: nil)
        isCameraStarted = sender.isSelected
        if (sender.isSelected) {
            buttonZoomIn.isHidden = true
            buttonZoomOut.isHidden = true
            buttonClose.isHidden = true
            buttonsFlash.isHidden = true
            lblInstruction.text = InstructionEnum.keepArrow.rawValue
            motionaObserver()
        } else {
            motionManager?.stopDeviceMotionUpdates()
            if (avCameraImageArray.count > Constants.minRequiredImage) {
                joinImages()
            } else {
                resetCamera()
            }
        }
    }
    
    @IBAction func onClickOfClose(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickOfFlash(_ sender: UIButton) {
        guard let currentDevice else { return }
        currentDevice.torchMode = currentDevice.torchMode == .on ? .off : .on
        buttonsFlash.setImage(UIImage(named: currentDevice.torchMode == .on ? ImageEnum.flashOn.rawValue : ImageEnum.flashOf.rawValue), for: .normal)
    }
    
    @IBAction func onClickOfZoomIn(_ sender: UIButton) {
        guard let currentDevice else { return }
        currentDevice.videoZoomFactor += Constants.zoomFactor
        buttonZoomOut.isEnabled = true
        buttonZoomIn.isEnabled = currentDevice.videoZoomFactor != Constants.maxZoomFactor
    }
    
    @IBAction func onClickZoomOut(_ sender: UIButton) {
        guard let currentDevice else { return }
        if (currentDevice.videoZoomFactor > Constants.zoomFactor) {
            currentDevice.videoZoomFactor -= Constants.zoomFactor
        }
        buttonZoomIn.isEnabled = currentDevice.videoZoomFactor >= Constants.zoomFactor
        buttonZoomOut.isEnabled = currentDevice.videoZoomFactor != Constants.zoomFactor
    }
    
}

// MARK: - configureSession
extension SSVerticalPanoController {
    
    func configureSession() {
        motionManager = CMMotionManager()
        buttonZoomOut.isEnabled = false
        // Get the front and back-facing camera for taking photos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        for device in deviceDiscoverySession.devices {
            if device.position == .back {
                currentDevice = device
            }
        }
        guard let currentDevice else { return }
        do {
            try currentDevice.lockForConfiguration()
        } catch {
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: currentDevice)
            captureSession.addInput(input)
        } catch {
            return
        }
        let videoOutput = AVCaptureVideoDataOutput()
        let dataOutputQueue = DispatchQueue(label: Constants.videoLabel,
                                            qos: .userInitiated,
                                            attributes: [],
                                            autoreleaseFrequency: .workItem)
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        // Provide a camera preview
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if let cameraPreviewLayer {
            view.layer.addSublayer(cameraPreviewLayer)
        }
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = viewCamera.frame
        bringViewsFront()
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            startCameraSession()
        }
    }
    
}

//MARK:- Motion Observeer
extension SSVerticalPanoController {
    
    func motionaObserver() {
        motionManager?.startDeviceMotionUpdates()
        if let motionManager = motionManager {
            motionManager.deviceMotionUpdateInterval = Constants.timeInterval
            if let operationQueue = OperationQueue.current {
                motionManager.startDeviceMotionUpdates(to: operationQueue) { (deviceMotion, deviceMotionError) in
                    if (self.isCameraStarted) {
                        self.handleDeviceMotionUpdates(deviceMotion!)
                    }
                }
            }
        }
    }
    
    func handleDeviceMotionUpdates(_ deviceMotion: CMDeviceMotion){
        updateVerticalDistance(deviceMotion: deviceMotion)
        updateHorizontalDistance(deviceMotion: deviceMotion)
        if (verticalArrowDistance - partialCapturedDistance > (Constants.imageCaptureRate)) {
            partialCapturedDistance = verticalArrowDistance
            needToTakeImage = true
        }
        if (verticalArrowDistance > (viewCenter.bounds.height - Constants.arrowHeight)) {
            isCameraStarted = false
            imageArrow.isHidden = true
            motionManager?.stopDeviceMotionUpdates()
            joinImages()
        }
        resetIfNotAlignCamera()
    }
    
    func updateHorizontalDistance(deviceMotion: CMDeviceMotion) {
        horizontalDistance += (getRoundedData(distance: deviceMotion.rotationRate.y)) / Constants.horizontalRotationConstant
        constraintArrowXAlign.constant = horizontalDistance
        if (horizontalDistance > Constants.maxHorizontalDistance) {
            lblInstruction.text = InstructionEnum.moveLeft.rawValue
        } else if (horizontalDistance < -Constants.maxHorizontalDistance) {
            lblInstruction.text = InstructionEnum.moveRight.rawValue
        } else if (partialCapturedDistance < Constants.maxKeepArrowDistance) {
            lblInstruction.text = InstructionEnum.keepArrow.rawValue
        } else if (getVerticalSpeed() < Constants.minSpeed) {
            lblInstruction.text = InstructionEnum.stablePosition.rawValue
        } else {
            lblInstruction.text = InstructionEnum.slowDown.rawValue
        }
    }
    
    func updateVerticalDistance(deviceMotion: CMDeviceMotion) {
        
        //Vertical Distance calculation
        let accelaration  = getAccelaration(from: deviceMotion.userAcceleration)
        let velocity = accelaration * Constants.timeInterval
        var distanceForTimeFrame = (Constants.halfDouble * pow(Constants.timeInterval, Constants.two) * accelaration ) + (velocity  * Constants.timeInterval)
        distanceForTimeFrame *=  Constants.verticalCaptureDistance
        
        //Check for error distance due to y or z movements and remove
        var error = Constants.zeroDouble
        if (abs(deviceMotion.rotationRate.y) > abs(deviceMotion.rotationRate.x) && abs(deviceMotion.rotationRate.y) > abs(deviceMotion.rotationRate.z)) {
            error = abs(deviceMotion.rotationRate.y)
        } else if (abs(deviceMotion.rotationRate.z) > abs(deviceMotion.rotationRate.x) && abs(deviceMotion.rotationRate.z) > abs(deviceMotion.rotationRate.y)) {
            error = abs(deviceMotion.rotationRate.z)
        }
        let distanceRotation = getRoundedData(distance: abs(deviceMotion.rotationRate.x))
        if (distanceForTimeFrame < Constants.leanerRotationFactor) {
            distanceForTimeFrame += (distanceForTimeFrame - error) * Constants.distanceErorConstant
        } else {
            distanceForTimeFrame = distanceRotation * Constants.tenDouble
        }
        if (distanceForTimeFrame >= Constants.minMovementDistance) {
            addVerticalSpeed(currentDistance: distanceForTimeFrame)
            verticalArrowDistance += distanceForTimeFrame
            verticalArrowDistance = getRoundedData(distance: verticalArrowDistance)
        } else {
            addVerticalSpeed(currentDistance: Constants.zeroDouble)
        }
    }
    
}


//MARK: - Camera Setup
extension SSVerticalPanoController {
    
    private func startCameraSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let uSelf = self else { return }
            // This is run on a background queue
            uSelf.captureSession.startRunning()
        }
    }
    
}

//MARK: - bringViewsFront
extension SSVerticalPanoController {
    
    func bringViewsFront() {
        // Bring the view to front
        view.bringSubviewToFront(buttonTakePhoto)
        view.bringSubviewToFront(viewCenter)
        view.bringSubviewToFront(viewCenterLine)
        view.bringSubviewToFront(imageArrow)
        view.bringSubviewToFront(imagePreview)
        view.bringSubviewToFront(viewActivityIndicator)
        view.bringSubviewToFront(activityIndicator)
        view.bringSubviewToFront(buttonClose)
        view.bringSubviewToFront(buttonsFlash)
        view.bringSubviewToFront(buttonZoomIn)
        view.bringSubviewToFront(buttonZoomOut)
        view.bringSubviewToFront(viewInstruction)
        view.bringSubviewToFront(lblInstruction)
    }
    
}

// MARK: - Reset Camera
extension SSVerticalPanoController {
    
    func resetCamera() {
        self.stitchingTask?.cancel()
        self.avCameraImageArray = []
        self.motionManager?.stopDeviceMotionUpdates()
        self.buttonTakePhoto.isSelected = false
        self.isCameraStarted = false
        self.needToTakeImage = true
        self.verticalArrowDistance = Constants.initialVerticalDistance
        self.partialCapturedDistance = Constants.zeroDouble
        self.horizontalDistance = Constants.zeroDouble
        self.verticalArrowDistance = Constants.initialArrowDistance
        self.constraintArrowXAlign.constant = Constants.zeroDouble
        self.finalImage = nil
        self.lblInstruction.text = InstructionEnum.stablePosition.rawValue
        self.arrayOfSpeed = []
        self.showProgressBar(show: false)
    }
    
    func resetIfNotAlignCamera() {
        if (verticalArrowDistance < -(Constants.tenDouble)  || constraintArrowXAlign.constant > (viewCenter.bounds.width / Constants.two) + Constants.tenDouble || -(constraintArrowXAlign.constant) > (viewCenter.bounds.width / Constants.two) + Constants.tenDouble) {
            resetCamera()
        }
    }
}

// MARK: - PreviewDismissDelegate
extension SSVerticalPanoController: PreviewDismissDelegate {
    func onClickOfDoneImage(image: UIImage) {
        delegate?.onImageCaptured(image: image)
        navigationController?.popViewController(animated: true)
    }
    
    func onClickOfRetake() {
        resetCamera()
        startCameraSession()
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension SSVerticalPanoController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if (needToTakeImage && isCameraStarted) {
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let image = self.convertAndUpdateUI(ciImage: CIImage(cvPixelBuffer: imageBuffer))
                DispatchQueue.main.async {
                    self.imagePreview?.image = image
                }
                self.avCameraImageArray.append(image)
                self.needToTakeImage = false
            }
        } else if (!isCameraStarted) {
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let image = self.convertAndUpdateUI(ciImage: CIImage(cvPixelBuffer: imageBuffer))
                DispatchQueue.main.async {
                    self.imagePreview?.image = image
                }
            }
        }
    }
    
}


//MARK: - Helper Func
extension SSVerticalPanoController {
    
    func getAccelaration(from acceleration: CMAcceleration) -> Double {
        return sqrt(pow(acceleration.x, Constants.two) +
                    pow(acceleration.y, Constants.two) +
                    pow(acceleration.z, Constants.two)) * Constants.gravityConstant
    }
    
    func getRoundedData(distance: Double) -> Double {
        return Double(round(Constants.thousand * distance) / Constants.thousand)
    }
    
    // Convert CIImage to UIImage
    func convertAndUpdateUI(ciImage: CIImage) -> UIImage {
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
}

//MARK: - stitchingComplete
extension SSVerticalPanoController {
    
    func stitchingComplete() {
        showPreviewScreen ? openPreviewImage() : onClickOfDoneImage(image: finalImage ?? UIImage())
    }
    
    private func openPreviewImage() {
        guard let previewController = UIStoryboard(name: StoryBoardEnum.ssStoryBoard.rawValue, bundle: nil).instantiateViewController(withIdentifier: ViewControllerEnum.previewController.rawValue) as? PreviewController, let finalImage = finalImage else {return}
        previewController.finalImage = finalImage
        previewController.delegate = self
        navigationController?.pushViewController(previewController, animated: true)
    }
    
}

//MARK: - Stitching
extension SSVerticalPanoController {
    
    func stitched(imageArray: [UIImage]) async throws -> UIImage {
        let stitchedImage:UIImage = try CVWrapper.process(with: imageArray)
        return stitchedImage
    }
    
    func joinImages() {
        showProgressBar(show: true)
        if (stitchingTask?.isCancelled ?? true) {
            stitchingTask = Task {
                do {
                    finalImage = try await stitched(imageArray: avCameraImageArray)
                    finalImage = finalImage?.rotate(radians: (.pi / Float(Constants.two)))
                    //Stitching Completed
                    showProgressBar(show: false)
                    if (finalImage != nil) {
                        stitchingComplete()
                    } else {
                        resetCamera()
                    }
                } catch let error as NSError {
                    debugPrint("Faild stiching \(error.localizedDescription)")
                    stitchingTask?.cancel()
                    resetCamera()
                    captureSession.startRunning()
                }
            }
        }
    }
    
}

// MARK: - Progress alert
extension SSVerticalPanoController {
    
    func showProgressBar(show: Bool) {
        self.viewActivityIndicator.isHidden = !show
        self.viewCamera.isHidden = show
        self.viewCenter.isHidden = show
        self.viewCenterLine.isHidden = show
        self.buttonTakePhoto.isHidden = show
        self.viewCamera.isHidden = show
        self.imageArrow.isHidden = show
        self.imagePreview.isHidden = show
        self.buttonZoomIn.isHidden = show
        self.buttonZoomOut.isHidden = show
        self.viewInstruction.isHidden = show
        self.lblInstruction.isHidden = show
        self.buttonClose.isHidden = show
        self.buttonsFlash.isHidden = show
        self.captureSession.stopRunning()
    }
    
}

//MARK: - Vertical Speed
extension SSVerticalPanoController {
    
    func addVerticalSpeed(currentDistance: Double) {
        if (arrayOfSpeed.count == Constants.minSpeedTimeFrame) {
            arrayOfSpeed.removeFirst()
        }
        arrayOfSpeed.append(currentDistance)
    }
    
    func getVerticalSpeed() -> Double {
        return arrayOfSpeed.reduce(Constants.zeroDouble, +)
    }
}

//MARK: - Obj Function
extension SSVerticalPanoController {
    @objc private func performCenterViewAction() {
        if (!isCameraStarted) {
            isTopToBottomDirection = !isTopToBottomDirection
        }
    }
    
    func updateTopConstraint() {
        self.constraintPreviewTop.priority = isTopToBottomDirection ? .defaultLow : .required
        self.constraintPreviewBottom.priority = isTopToBottomDirection ? .required : .defaultLow
        self.imageArrow.isHighlighted = !isTopToBottomDirection
        if (isTopToBottomDirection) {
            self.constraintArrowTop.constant = verticalArrowDistance
        } else {
            self.constraintArrowTop.constant = viewCenter.bounds.size.height - verticalArrowDistance - Constants.arrowHeight
        }
        self.imagePreview.isHidden = true
        UIView.animate(withDuration: Constants.halfDouble) {
            self.view.layoutIfNeeded()
        }
        UIView.transition(with: imagePreview, duration: Constants.animationDelay,
                          options: .transitionCrossDissolve,
                          animations: {
            self.imagePreview.isHidden = false
        })
    }
}
