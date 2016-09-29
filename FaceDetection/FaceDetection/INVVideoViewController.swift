//
//  INVVideoViewController.swift
//
//
//  Created by Krzysztof Kryniecki on 9/23/16.
//  Copyright © 2016 InventiApps. All rights reserved.
//

import UIKit
import AVFoundation

enum INVVideoControllerErrors: Error {
    case unsupportedDevice
    case undefinedError
}

protocol INVRecordingViewController {
    func startRecording()
    func stopRecording()
    func startCaptureSesion()
    func stopCaptureSession()
    func startMetaSession()
}

class INVVideoViewController: UIViewController {
    let sessionQueue = DispatchQueue(label: "session queue", qos: .utility,  target: nil)
    let captureSession = AVCaptureSession()
    var previewLayer:AVCaptureVideoPreviewLayer?
    var numberOfAuthorizedDevices = 0
    var runtimeCaptureErrorObserver:NSObjectProtocol?
    var movieFileOutputCapture:AVCaptureMovieFileOutput?
    var isRecording:Bool = false
    var outputFilePath:URL?
    let kINVRecordedFileName = "movie.mov"
    
    @IBOutlet weak var recordButton: UIButton!
    
    func checkDeviceAuthorizationStatus(handler:@escaping ((_ granted:Bool) -> Void))  {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: handler)
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: handler)
    }
    
    func setupPreviewView(session:AVCaptureSession) throws {
        if let previewLayer = AVCaptureVideoPreviewLayer(session: session) {
            previewLayer.masksToBounds = true
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
            self.previewLayer?.frame = self.view.frame
            self.view.bringSubview(toFront: self.recordButton)
            
        } else {
            throw INVVideoControllerErrors.undefinedError
        }
    }
    
    func deviceWithMediaType(mediaType:String, position:AVCaptureDevicePosition?) throws -> AVCaptureDevice? {
        if let devices = AVCaptureDevice.devices(withMediaType: mediaType)  {
            if let devicePosition = position {
                for deviceObj in devices {
                    if let device = deviceObj as? AVCaptureDevice, device.position == devicePosition {
                        return device
                    }
                }
            } else {
                if let device = devices.first as? AVCaptureDevice {
                    return device
                }
            }
        }
        throw INVVideoControllerErrors.unsupportedDevice
    }
    
    func setupCaptureSession() throws {
        let videoDevice = try self.deviceWithMediaType(mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.front)
        let captureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        if self.captureSession.canAddInput(captureDeviceInput) {
            self.captureSession.addInput(captureDeviceInput)
        } else {
            fatalError("Cannot add video recording input")
        }
        let audioDevice = try self.deviceWithMediaType(mediaType: AVMediaTypeAudio, position: nil)
        let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
        if self.captureSession.canAddInput(audioDeviceInput) {
            self.captureSession.addInput(audioDeviceInput)
        } else {
            fatalError("Cannot add audio recording input")
        }
    }
    
    // Sets Up Capturing Devices And Starts Capturing Session
    func runDeviceCapture(startSession:Bool) {
        do {
            try self.setupPreviewView(session: self.captureSession)
        } catch {
            fatalError("Undefined Error")
        }
        
        sessionQueue.async {
            do {
                try self.setupCaptureSession()
                DispatchQueue.main.async {
                    if startSession {
                        self.startCaptureSesion()
                        self.startMetaSession()
                    }
                }
            } catch INVVideoControllerErrors.unsupportedDevice {
                fatalError("Unsuported Device")
            } catch  {
                fatalError("Undefined Error")
            }
        }
    }
    
    func handleVideoRotation() {
        if let connection =  self.previewLayer?.connection  {
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            if previewLayerConnection.isVideoOrientationSupported, let videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) {
                previewLayer?.connection.videoOrientation = videoOrientation
            }
        }
    }
    
    func setupDeviceCapture() {
        if self.numberOfAuthorizedDevices == 2 { // Audio and Video Devices were already set up
            self.startCaptureSesion()
        } else {
            self.checkDeviceAuthorizationStatus { (granted) in
                if granted {
                    self.numberOfAuthorizedDevices += 1
                    if self.numberOfAuthorizedDevices >= 2 { //Audio and Video must be authorized to start capture session
                        DispatchQueue.main.async {
                            self.runDeviceCapture(startSession: true)
                        }
                    } 
                } else {
                    fatalError("Video and Audio Capture must be granted")
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setupDeviceCapture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let outputFilePath = self.outputFilePath {
            do {
                try FileManager.default.removeItem(at: outputFilePath)
                print("File Removed")
            } catch {
                print("Error while Deleting recorded File")
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopCaptureSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer?.frame = self.view.frame
        self.handleVideoRotation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override var shouldAutorotate: Bool {
        return true
    }
    
    func updateButtonTitle() {
        if self.isRecording {
            self.recordButton.setTitle("Stop Recording", for: .normal)
        } else {
            self.recordButton.setTitle("Start Recording", for: .normal)
        }
    }
    
    @IBAction func recordButtonPressed(_ sender: AnyObject) {
        if self.isRecording == false {
            self.startRecording()
        } else {
            self.stopRecording()
        }
        self.updateButtonTitle()
    }
}



extension INVVideoViewController:INVRecordingViewController {
    
    func startRecording() {
        self.setupMoviewFileOutput()
        self.outputFilePath = URL(fileURLWithPath: NSTemporaryDirectory() + kINVRecordedFileName)
        self.movieFileOutputCapture?.startRecording(toOutputFileURL: self.outputFilePath, recordingDelegate: self)
        self.isRecording = true
    }
    
    func stopRecording() {
        if self.isRecording {
            self.movieFileOutputCapture?.stopRecording()
            self.isRecording = false
        }
        self.updateButtonTitle()
        print("Stopped Capture Session")
    }
    
    func startCaptureSesion() {
        print("Started Capture Session")
        self.captureSession.startRunning()
        self.previewLayer?.connection.automaticallyAdjustsVideoMirroring = false
        self.previewLayer?.connection.isVideoMirrored = true
        
        self.runtimeCaptureErrorObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: self.captureSession, queue: nil) { [weak self] (note) in
            self?.showCaptureError()
        }
    }
    
    func stopCaptureSession() {
        self.sessionQueue.async {
            self.captureSession.stopRunning()
        }
        NotificationCenter.default.removeObserver(self.runtimeCaptureErrorObserver)
    }
    
    func startMetaSession() {
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
        if self.captureSession.canAddOutput(metadataOutput) {
            self.captureSession.addOutput(metadataOutput)
        } else {
           fatalError("Cannot Add Meta Capture Output")
        }
        metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace];
    }
}


