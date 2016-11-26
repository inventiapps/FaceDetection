//
//  INVWriter.swift
//  FaceDetection
//
//  Created by Krzysztof Kryniecki on 10/17/16.
//  Copyright © 2016 InventiApps. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary
import AVKit

let eaglContext = EAGLContext(api: EAGLRenderingAPI.openGLES2)
let coreImageContext = CIContext(eaglContext: eaglContext!, options: nil)
let filter = CIFilter(name: "CISourceOverCompositing")
let overlayImage = CIImage(image:UIImage(named:"overlay")!)

class INVWriter {
    var videoInput: AVAssetWriterInput
    var videoinputAdapter: AVAssetWriterInputPixelBufferAdaptor
    var audioInput: AVAssetWriterInput
    var assetWriter: AVAssetWriter
    let filePath: URL
    weak var delegate: UIViewController?

    init(outFilePath: URL, outputSettings: [String : Any],
         width: Float,
         height: Float,
         pixelBuffer: CVPixelBuffer) {
        do {
            filePath = outFilePath
            assetWriter = try AVAssetWriter(url: outFilePath as URL,
                                            fileType: AVFileTypeQuickTimeMovie)
            let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
            guard assetWriter.canApply(outputSettings: outputSettings,
                forMediaType: AVMediaTypeVideo) else {
                fatalError("Negative : Can't apply the Output settings...")
            }
            if let videoHeight = outputSettings[AVVideoHeightKey] as? Float,
                let videoWidth = outputSettings[AVVideoWidthKey] as? Float {
                let options = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value:format),
                    kCVPixelBufferWidthKey as String: NSNumber(value: videoWidth),
                    kCVPixelBufferHeightKey as String: NSNumber(value: videoHeight)
                ]
                videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                    outputSettings: outputSettings)
                videoInput.expectsMediaDataInRealTime = true
                videoinputAdapter = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: videoInput,
                    sourcePixelBufferAttributes: options)
                if assetWriter.canAdd(videoInput) {
                    assetWriter.add(videoInput)
                }
                audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil)
                audioInput.expectsMediaDataInRealTime = true
                if assetWriter.canAdd(audioInput) {
                    assetWriter.add(audioInput)
                }
            } else {
                videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                                                outputSettings: outputSettings)
                videoInput.expectsMediaDataInRealTime = true
                videoinputAdapter = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: videoInput,
                    sourcePixelBufferAttributes: nil)
                if assetWriter.canAdd(videoInput) {
                    assetWriter.add(videoInput)
                }
                audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil)
                audioInput.expectsMediaDataInRealTime = true
            }
        } catch {
            fatalError("Failed Creating Writer")
        }
    }

    func start(startTime: CMTime) {
        self.assetWriter.startWriting()
        self.assetWriter.startSession(atSourceTime: startTime)
    }

    func stop() {
        self.videoInput.markAsFinished()
        self.assetWriter.finishWriting {
            if self.assetWriter.error != nil {
                print("Error converting images to video: \(self.assetWriter.error)")
            } else {
                print("Finished Writing")
                self.playVideo()
            }
        }
    }

    func writeVideo(sampleBuffer: CMSampleBuffer) {
        if  let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let beginImage = CIImage(cvPixelBuffer: pixelBuffer)
            filter?.setValue(overlayImage, forKey: kCIInputImageKey)
            filter?.setValue(beginImage, forKey: kCIInputBackgroundImageKey)
            let output = filter!.outputImage
            let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            var outputBuffer: CVPixelBuffer?
            let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
            let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                             Int(output!.extent.size.width),
                                             Int(output!.extent.size.height),
                                             format,
                                             nil,
                                             &outputBuffer)
            if status == kCVReturnSuccess {
                coreImageContext.render(output!,
                    to: outputBuffer!,
                    bounds: beginImage.extent,
                    colorSpace: CGColorSpaceCreateDeviceRGB())
                self.videoinputAdapter.append(outputBuffer!, withPresentationTime: time)
            } else {
                print("Failed to render Frame")
                return
            }
        }
    }

    func write(sampleBuffer: CMSampleBuffer, isVideo: Bool) {
        if isVideo == false {
            if self.audioInput.isReadyForMoreMediaData {
                self.audioInput.append(sampleBuffer)
            }
        } else {
            if self.videoInput.isReadyForMoreMediaData {
                self.writeVideo(sampleBuffer: sampleBuffer)
            }
        }
    }

    func playVideo() {
        if self.assetWriter.status == .completed {
            DispatchQueue.main.async {
                let videoController = AVPlayerViewController()
                videoController.player = AVPlayer(url: self.filePath)
                self.delegate?.present(videoController, animated: true) {
                    videoController.player?.play()
                }
            }
        }
    }
}
