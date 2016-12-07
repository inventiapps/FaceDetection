//
//  INVVideoOutputDelegate.swift
//  FaceDetection
//
//  Created by Krzysztof Kryniecki on 12/7/16.
//  Copyright © 2016 InventiApps. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit


extension INVVideoViewController: AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
        if !CMSampleBufferDataIsReady(sampleBuffer) {
            print("sample buffer is not ready. Skipping sample")
            return
        }
        cameraQueue.sync {
            if self.recordingActivated {
                if self.writer == nil,
                    let pixelBuffler = CMSampleBufferGetImageBuffer(sampleBuffer),
                    let outputSettings = self.captureOutput?.recommendedVideoSettingsForAssetWriter(
                        withOutputFileType: AVFileTypeQuickTimeMovie) as? [String : Any] {
                    self.writer = INVWriter(
                        outFilePath: self.outputFilePath!,
                        outputSettings: outputSettings,
                        width: Float(self.view.bounds.width),
                        height: Float(self.view.bounds.height), pixelBuffer: pixelBuffler)
                    let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    self.writer?.start(startTime: time)
                }
                if self.writer != nil {
                    if captureOutput is AVCaptureVideoDataOutput {
                        outputQueue.async {
                            self.writer?.write(sampleBuffer: sampleBuffer, isVideo: true)
                        }
                    } else {
                        audioOutputQueue.async {
                            self.writer?.write(sampleBuffer: sampleBuffer, isVideo: false)
                        }
                    }
                }
            }
        }
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didDrop sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
    }
}
