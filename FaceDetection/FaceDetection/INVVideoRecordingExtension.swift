//
//  INVVideoRecordingExtension.swift
//
//  Created by Krzysztof Kryniecki on 9/29/16.
//  Copyright © 2016 InventiApps. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

extension INVVideoViewController: AVCaptureFileOutputRecordingDelegate {

    func playVideo() {
        if let outuputFile = self.outputFilePath {
            print("Output \(outuputFile)")
            let videoController = AVPlayerViewController()
            videoController.player = AVPlayer(url: outuputFile)
            self.present(videoController, animated: true) {
                videoController.player?.play()
            }
        }
    }

    func capture(_ captureOutput: AVCaptureFileOutput!,
                 didFinishRecordingToOutputFileAt outputFileURL: URL!,
                 fromConnections connections: [Any]!, error: Error!) {
        if error != nil {
            print("Error occured during recording \(error.localizedDescription)")
            self.showCaptureError()
        } else {
            self.playVideo()
            print("Finished Recording")
        }
    }

    func setupMoviewFileOutput() {
        if self.movieFileOutputCapture != nil {
        } else {
            self.movieFileOutputCapture = AVCaptureMovieFileOutput()
            if self.captureSession.canAddOutput(self.movieFileOutputCapture) {
                self.captureSession.addOutput(self.movieFileOutputCapture)
                let connection = self.movieFileOutputCapture?.connection(
                    withMediaType: AVMediaTypeVideo)
                connection?.isVideoMirrored = true
            } else {
                fatalError("Cannot Add Movie File Output")
            }
        }
    }

    func showCaptureError() {
        let alert = UIAlertController(title:"Error",
                                      message: "Something Went Wrong While Recording",
                                      preferredStyle: .alert)
        let alertOkAction = UIAlertAction(title: "Cancel Recording",
                                          style: .cancel,
                                          handler: { (action) in
            self.stopCaptureSession()
            self.stopRecording()
        })
        let alertRestartAction = UIAlertAction(title: "Restart Recording",
                                               style: .cancel, handler: { (action) in
            self.sessionQueue.async {
                self.captureSession.startRunning()
                if self.isRecording {
                    self.startRecording()
                }
            }
        })
        alert.addAction(alertOkAction)
        alert.addAction(alertRestartAction)
        alert.show(self, sender: nil)
    }
}
