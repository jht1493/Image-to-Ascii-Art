//
//  DisplayViewController.swift
//  ImageToAsciiArt
//
//  Created by Liam Rosenfeld on 11/11/17.
//  Copyright © 2017 Liam Rosenfeld. All rights reserved.
//

import UIKit
import AsciiConverter
import Firebase
import MessageUI

class DisplayViewController: UIViewController {

    // MARK: - Setup
    private let labelFont = UIFont(name: "Menlo", size: 7)!
    private let maxImageSize = CGSize(width: 310, height: 310)
    private lazy var palette: AsciiPalette = AsciiPalette(font: self.labelFont)
    
    var currentLabel: UILabel?
    @IBOutlet weak var busyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    let ImagePickerController = UIImagePickerController()
    
    var asciiArt:String?
    var picSelectMethod: String?
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureZoomSupport()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if picSelectMethod! == "homePickImage" {
            pickImage()
            picSelectMethod = "done"
        } else if picSelectMethod! == "homeTakePicture" {
            takePicture()
            picSelectMethod = "done"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Actions
    @IBAction func backToHome(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func newImage(_ sender: UIButton) {
        selectAnother()
    }
    
    @IBAction func share(_ sender: UIButton) {
        if self.asciiArt != nil {
            self.showShareMenu(sender)
        } else {
            alert(title: "Woah There!", message: "Please pick an image first", dismissText: "OK")
        }
    }
    
    // Save as Image
    func image(from view: UIScrollView) -> UIImage? {
        UIGraphicsBeginImageContext(view.contentSize)
        
        let savedContentOffset = view.contentOffset
        let savedFrame = view.frame
        
        view.contentOffset = CGPoint.zero
        view.frame = CGRect(x: 0, y: 0, width: view.contentSize.width, height: view.contentSize.height)
        
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        view.contentOffset = savedContentOffset
        view.frame = savedFrame
        
        UIGraphicsEndImageContext()
        
        return image
    }

    
    // MARK: - Rendering
    func displayImage(_ image: UIImage) {
        self.busyView.isHidden = false
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            let // Rotate first because the orientation is lost when resizing.
            rotatedImage = image.imageRotatedToPortraitOrientation(),
            resizedImage = rotatedImage.imageConstrainedToMaxSize(self.maxImageSize),
            asciiArtist  = AsciiArtist(resizedImage, self.palette),
            asciiArt     = asciiArtist.createAsciiArt()
            
            DispatchQueue.main.async {
                self.displayAsciiArt(asciiArt)
                self.busyView.isHidden = true
                self.scrollView.backgroundColor = UIColor.white
                Analytics.logEvent("convert", parameters: nil)
            }
            
            self.asciiArt = asciiArt
        }
    }
    
    private func displayAsciiArt(_ asciiArt: String) {
        let
        label = UILabel()
        label.font = self.labelFont
        label.lineBreakMode = NSLineBreakMode.byClipping
        label.numberOfLines = 0
        label.text = asciiArt
        label.sizeToFit()
        
        currentLabel?.removeFromSuperview()
        currentLabel = label
        
        scrollView.addSubview(label)
        scrollView.contentSize = label.frame.size
        
        self.updateZoomSettings(animated: false)
        scrollView.contentOffset = CGPoint.zero
        
        self.asciiArt = asciiArt
    }

    
    // MARK: - UIAlertController
    func showShareMenu(_ sender: UIButton) {
        let shareMenu = UIAlertController(title: "Share", message: nil, preferredStyle: .actionSheet)
        
        let copy = UIAlertAction(title: "Copy", style: .default) { action in
            UIPasteboard.general.string = self.asciiArt
            self.alert(title: "Copied!", message: nil, dismissText: "Yay!")
            Analytics.logEvent(AnalyticsEventShare, parameters: nil)
        }
        
        let image = UIAlertAction(title: "Image", style: .default) { action in
            UIImageWriteToSavedPhotosAlbum(self.image(from: self.scrollView)!, nil, nil, nil)
            self.alert(title: "Saved!", message: nil, dismissText: "Yay!")
            Analytics.logEvent(AnalyticsEventShare, parameters: nil)
        }
        
        let send = UIAlertAction(title: "iMessage", style: .default) { action in
            self.sendMessage(with: self.asciiArt!)
            Analytics.logEvent(AnalyticsEventShare, parameters: nil)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        shareMenu.addAction(copy)
        shareMenu.addAction(image)
        if MFMessageComposeViewController.canSendText() {
            shareMenu.addAction(send)
        } else {
            print("SMS services are not available")
        }
        shareMenu.addAction(cancel)
        
        if let popoverController = shareMenu.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        
        present(shareMenu, animated: true, completion: nil)
    }
    
    func alert(title: String, message: String?, dismissText: String) {
        let alert = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: dismissText, style: UIAlertAction.Style.default,handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}
