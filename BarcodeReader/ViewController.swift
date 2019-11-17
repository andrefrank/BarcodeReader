//
//  ViewController.swift
//  BarcodeReader
//
//  Created by Andre Frank on 16.11.19.
//  Copyright © 2019 Afapps+. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    // MARK: - IBOutlets
    
    @IBOutlet var resultView: UITextView!
    @IBOutlet var previewView: UIView!
    
    @IBOutlet var scanToggleButton: UIButton!
    
    // MARK: - Properties
    var scanner: BarcodeScanner?
    
    var isScanning = false {
        willSet {
            let title = newValue ? "Stop scan" : "Start scan"
            scanToggleButton.setTitle(title, for: .normal)
        }
    }
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //1. Initialize scanner
        scanner = BarcodeScanner(completion: handleCode(code:), queue: DispatchQueue.main, previewIn: previewView)
        
        //2. setup GUI
        setupControls()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        scanner?.requestScannerStopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scanner?.updateOrientation()
    }
    
    // MARK: - IBActions
    
    @IBAction func startScanButtonPressed(_ sender: Any) {
        guard let scanner = self.scanner else {
            return
        }
        
        if !isScanning {
            isScanning=scanner.requestScannerStartRunning()
            
        } else {
            scanner.requestScannerStopRunning()
            isScanning = false
        }
    }
    
    // MARK: - ViewController Methods
    
    /// Setup GUI
    func setupControls() {
       
        ///Use same corner radius for all visible controls
        if let previewlayer = previewView.layer.sublayers?.first(where: {$0 is AVCaptureVideoPreviewLayer}) as? AVCaptureVideoPreviewLayer {
            previewlayer.cornerRadius = 10
            previewlayer.frame = previewView.bounds.insetBy(dx: 2,dy: 2)
        }
        
        resultView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 10, right: 8)
         resultView.isEditable = false
         resultView.layer.cornerRadius = 10
        
        scanToggleButton.layer.cornerRadius = 10
        
    }
    
    /// Completion handler from Barcode scanner
    func handleCode(code: String) {
        let previousColor = previewView.backgroundColor
        previewView.backgroundColor = UIColor.green
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) { [weak self] in
            self?.previewView.backgroundColor = previousColor
        }
        resultView.text += code + "\n"
    }
}
