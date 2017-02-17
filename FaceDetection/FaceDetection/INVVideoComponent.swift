//
//  INVVideoComponent.swift
//  FaceDetection
//
//  Created by Krzysztof Kryniecki on 2/17/17.
//  Copyright © 2017 InventiApps. All rights reserved.
//

import UIKit
import AVFoundation
class INVVideoComponent: NSObject {
    private let videoController: INVVideoViewController = INVVideoViewController()
    enum INVVideoComponentState {
        case ready
        case unknown
        case error
    }

    enum INVVideoComponentAction {
        case livePreview
        case unknown
    }
    private var action: INVVideoComponentAction = .unknown
    private var cameraType: AVCaptureDevicePosition
    private var state: INVVideoComponentState = .unknown {
        didSet {
            switch state {
            case .ready:
                if action != .unknown {
                    self.performAction(action: action)
                }
                break
            case .error:
                break
            case .unknown:
                break
            }
        }
    }

    init(
        atViewController viewController: UIViewController,
        cameraType: AVCaptureDevicePosition,
        withAccess access: INVVideoAccessType
    ) {
        self.cameraType = cameraType
        super.init()
        viewController.addChildViewController(self.videoController)
        viewController.view.addSubview(self.videoController.view)
        self.videoController.didMove(toParentViewController: viewController)
        self.videoController.errorBlock = { error in
            self.showAlert(error: error)
            self.state = .error
        }
        self.videoController.componentReadyBlock = { [weak self] in
            self?.state = .ready
        }
        self.videoController.setupDeviceCapture(requiredAccessType: .both)
        self.videoController.configureDeviceCapture(cameraType: self.cameraType)
    }

    private func performAction(action: INVVideoComponentAction) {
        switch action {
        case .livePreview:
            self.videoController.startCaptureSesion()
            self.videoController.startMetaSession()
            break
        case .unknown:
            break
        }
    }

    private func scheduleAction(action: INVVideoComponentAction) {
        self.action = action
        if self.state == .ready {
            self.performAction(action: action)
        }
    }

    func showAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        let controller = UIApplication.shared.keyWindow?.rootViewController
        controller?.present(alert, animated: true, completion: nil)
    }

    func startLivePreview() {
        self.scheduleAction(action: .livePreview)
    }

    func stopLivePreview() {
        self.videoController.stopCaptureSession()
    }
}
