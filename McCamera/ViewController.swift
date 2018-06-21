//
//  ViewController.swift
//  openCamera
//
//  Created by Veck on 2017/1/5.
//  Copyright © 2018 By Cyril. All rights reserved.
//

import Cocoa
import AVFoundation
import Vision
import AVKit

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var camera: NSView!
    
    @IBOutlet weak var results_label: NSTextField!
    
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        camera.layer = CALayer()
        
        
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSession.Preset.low
        
        // Get all audio and video devices on this machine
        let device = AVCaptureDevice.devices(for: .video).first
        
        captureDevice = device!
        
        if captureDevice != nil {
            
            do {
                
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice!))
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.frame = (self.camera.layer?.frame)!
                
                // Add previewLayer into custom view
                self.camera.layer?.addSublayer(previewLayer!)
                
                // Start camera
                captureSession.startRunning()
                
            } catch {
                print(AVCaptureSessionErrorKey.description)
            }
        }
        
        let data_output = AVCaptureVideoDataOutput()
        data_output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(data_output)
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixel_buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (request, err) in
            
            guard let results = request.results as? [VNClassificationObservation] else { return }
            guard let first_observtion = results.first else { return }
            
            let text = "\(first_observtion.identifier), \(first_observtion.confidence * 100)%"
            
            DispatchQueue.main.async {
               self.results_label.stringValue = text
            }
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixel_buffer, options: [:]).perform([request])
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
}

