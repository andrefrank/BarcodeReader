//
//  Scanner.swift
//  BarcodeReader
//
//  Created by Andre Frank on 16.11.19.
//  Copyright © 2019 Afapps+. All rights reserved.
//

import AVFoundation
import UIKit

class BarcodeScanner: NSObject {
    typealias BarcodeScannerCompletion = (_ code: String) -> Void
    
    private var player: AVAudioPlayer?
    private var captureSession: AVCaptureSession?
    private var outputHandler: BarcodeScannerCompletion
    private var queue: DispatchQueue!
    private var previewView: UIView!
    
    private var previousCodes: String?
    
    init?(completion: @escaping BarcodeScannerCompletion, queue: DispatchQueue?, previewIn view: UIView) {
        outputHandler = completion
        self.queue = queue
        /// NSObject
        super.init()
        
        // Create Session
        guard let captureSession = createCaptureSession() else {
            return nil
        }
        self.captureSession = captureSession
        
        // Preview scan
        let previewlayer = createPreviewLayer(withSession: captureSession, view: view)
        
        previewView = view
        view.layer.addSublayer(previewlayer)
        
        // Init Scan sound if available
        self.player = createAudioPlayer()
    }
    
    func requestScannerStartRunning() -> Bool {
        guard let captureSession = self.captureSession else {
            return false
        }
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
        
        return true
    }
    
    func requestScannerStopRunning() {
        guard let captureSession = self.captureSession else {
            return
        }
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    private func createCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return nil }
        
        /// Try to set input / output of the session
        do {
            // Get input
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            let metaDataOutput = AVCaptureMetadataOutput()
            
            // Add input when possible
            guard captureSession.canAddInput(input) else {
                return nil
            }
            captureSession.addInput(input)
            
            guard captureSession.canAddOutput(metaDataOutput) else {
                return nil
            }
            // Add output
            captureSession.addOutput(metaDataOutput)
            // Set delegate for the output
            metaDataOutput.setMetadataObjectsDelegate(self, queue: queue ?? DispatchQueue.main)
            // Set types of barcodes to scan
            metaDataOutput.metadataObjectTypes = metaObjectTypes()
            
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
        return captureSession
    }
    
    private func metaObjectTypes() -> [AVMetadataObject.ObjectType] {
        return [
            .code128,
            .code39,
            .dataMatrix,
            .qr,
            .code39Mod43,
            .ean8,
            .interleaved2of5,
            .code93,
            .ean13,
            .upce
        ]
    }
    
    private func createPreviewLayer(withSession captureSession: AVCaptureSession, view: UIView) -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // previewLayer.frame = view.bounds.insetBy(dx: 2,dy: 5)
        previewLayer.videoGravity = .resizeAspectFill
        
        return previewLayer
    }
}

extension BarcodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metaDataObject = metadataObjects.first {
            guard let readableObject = metaDataObject as? AVMetadataMachineReadableCodeObject, let newCode = readableObject.stringValue else {
                return
            }
            
            /// Send code only if  no code exists or a new one has read
            if let oldCode = previousCodes {
                guard newCode != oldCode else {
                    return
                }
                //Release Metadata object before retaining it will prevent memory leaks
                previousCodes = nil
                
                playBeep()
                outputHandler(newCode)
                //This code retains the MetadataObject containing the stringValue
                previousCodes = newCode
                
            } else {
                 //Release Metadata object before retaining it will prevent memory leaks
                previousCodes = nil
                playBeep()
                outputHandler(newCode)
                //This code retains the Metadata objectcontaining the stringValue
                previousCodes = newCode
            }
        }
    }
}

extension BarcodeScanner {
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        
        guard let previewLayer = self.previewView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else {
            return }
        
        previewLayer.cornerRadius = 10
        previewLayer.frame = previewView.bounds.insetBy(dx: 2, dy: 2)
    }
    
    func updateOrientation() {
        guard let previewLayer = self.previewView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else {
            return }
        
        if let connection = previewLayer.connection {
            let currentDevice: UIDevice = UIDevice.current
            
            let orientation: UIDeviceOrientation = currentDevice.orientation
            
            let previewLayerConnection: AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                switch orientation {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    
                    break
                    
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    
                    break
                    
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    
                    break
                    
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    
                    break
                    
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    
                    break
                }
            }
        }
    }
}

extension BarcodeScanner {
    func createAudioPlayer() -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: "beep", withExtension: "mp3") else { return nil}
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            return player
            
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func playBeep() {
        guard let player = player else { return }
        
        player.play()
    }
}
