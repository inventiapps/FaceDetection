//
//  INVVideoMetaExtension.swift
//
//  Created by Krzysztof Kryniecki on 9/29/16.
//  Copyright © 2016 InventiApps. All rights reserved.
//
import UIKit
import AVFoundation

extension INVVideoViewController:AVCaptureMetadataOutputObjectsDelegate {
    func printFaceLayer(layer: CALayer, faceObjects: [AVMetadataFaceObject]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        // hide all the face layers
        var faceLayers = [CALayer]()
        for layer: CALayer in layer.sublayers! {
            if layer.name == "face" {
                faceLayers.append(layer)
            }
        }
        for faceLayer in faceLayers {
            faceLayer.removeFromSuperlayer()
        }
        for faceObject in faceObjects {
            let featureLayer = CALayer()
            featureLayer.frame = faceObject.bounds
            featureLayer.borderColor = UIColor.green.cgColor
            featureLayer.borderWidth = 1.0
            featureLayer.name = "face"
            layer.addSublayer(featureLayer)
        }
        CATransaction.commit()
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputMetadataObjects metadataObjects: [Any]!,
                       from connection: AVCaptureConnection!) {
        var faceObjects = [AVMetadataFaceObject]()
        for metadataObject in metadataObjects {
            if let metaFaceObject = metadataObject as? AVMetadataFaceObject,
                metaFaceObject.type == AVMetadataObjectTypeFace {
                if let object = self.previewLayer?.transformedMetadataObject(
                    for: metaFaceObject) as? AVMetadataFaceObject {
                    faceObjects.append(object)
                }
            }
        }
        if faceObjects.count > 0, let layer = self.previewLayer {
            self.printFaceLayer(layer: layer, faceObjects: faceObjects)
        }
    }
}
