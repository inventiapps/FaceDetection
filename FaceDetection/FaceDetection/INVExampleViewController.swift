//
//  INVExampleViewController.swift
//  FaceDetection
//
//  Created by Krzysztof Kryniecki on 2/17/17.
//  Copyright © 2017 InventiApps. All rights reserved.
//

import UIKit
import AVFoundation
final class INVExampleViewController: UIViewController {
    private var videoComponent: INVVideoComponent?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoComponent = INVVideoComponent(
            atViewController: self,
            cameraType: .front,
            withAccess: .both
        )
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.videoComponent?.startLivePreview()
    }
}
