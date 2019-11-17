//
//  ViewController.swift
//  BarcodeReader
//
//  Created by Andre Frank on 16.11.19.
//  Copyright © 2019 Afapps+. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var resultView: UITextView!
    @IBOutlet weak var previewView: UIView!
    
    var isScanning=false
    
    var scanner:BarcodeScanner?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        previewView.layer.cornerRadius = 10
        resultView.layer.cornerRadius = 10
        resultView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        
        
        scanner = BarcodeScanner(completion: handleCode(code:), queue: DispatchQueue.main, previewIn: previewView)
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        scanner?.requestScannerStopRunning()
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //scanner?.updateOrientation()
    }
    
    func handleCode(code:String)->Void{
        let previousColor = previewView.backgroundColor
        previewView.backgroundColor = UIColor.green
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.3) {[weak self] in
            self?.previewView.backgroundColor = previousColor
        }
        resultView.text += code + "\n"
    }
    
    
    @IBAction func startScanButtonPressed(_ sender: Any) {
        if !isScanning{
            scanner?.requestScannerStartRunning()
            isScanning=true
        }else{
            scanner?.requestScannerStopRunning()
            isScanning=false
        }
        
        
    }
    
}

