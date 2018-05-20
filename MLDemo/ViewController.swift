//
//  ViewController.swift
//  MLDemo
//
//  Created by PeterDing on 2018/5/20.
//  Copyright © 2018年 DinDin. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController {

    @IBOutlet weak var mainImageView: UIImageView! {
        didSet {
            mainImageView.backgroundColor = UIColor.gray
        }
    }
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var mainLabel: UILabel!
    var model: Inceptionv3!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        model = Inceptionv3()
        mainLabel.text = "waiting for Anazyling"

    }

    @IBAction func toCameraButton(_ sender: UIBarButtonItem) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return
        }
        let camerPickerVC = UIImagePickerController()
        camerPickerVC.delegate = self
        camerPickerVC.sourceType = .camera
        present(camerPickerVC, animated: true, completion: nil)
        
    }
}


extension ViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)

        mainLabel.text = "Anazyling Image"
        
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
        UIGraphicsBeginImageContext(CGSize(width: 299, height: 299))
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return
        }
        UIGraphicsEndImageContext()
        let attri = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attri, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
        let pixeData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixeData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        mainImageView.image = newImage
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        let title = prediction.classLabel
        mainLabel.text = "It's \(title)"
        let info = prediction.classLabelProbs[title] ?? 0
        infoLabel.text = " \(info)"

    }
}
