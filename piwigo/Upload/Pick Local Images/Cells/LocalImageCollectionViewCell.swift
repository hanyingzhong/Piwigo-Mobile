//
//  LocalImageCollectionViewCell.swift
//  piwigo
//
//  Created by Spencer Baker on 1/28/15.
//  Copyright (c) 2015 bakercrew. All rights reserved.
//
//  Converted to Swift 5.1 by Eddy Lelièvre-Berna on 13/04/2020
//

import Photos
import UIKit

@objc
class LocalImageCollectionViewCell: UICollectionViewCell {

    private var _cellSelected = false
    @objc var cellSelected: Bool {
        get {
            _cellSelected
        }
        set(cellSelected) {
            _cellSelected = cellSelected

            selectedImage?.isHidden = !cellSelected
            darkenView?.isHidden = !cellSelected
        }
    }

    private var _cellUploading = false
    @objc var cellUploading: Bool {
        get {
            _cellUploading
        }
        set(uploading) {
            _cellUploading = uploading

            uploadingView?.isHidden = !uploading
        }
    }

    private var _progress: CGFloat = 0.0
    @objc var progress: CGFloat {
        get {
            _progress
        }
        set(progress) {
            setProgress(progress, withAnimation: true)
        }
    }
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var darkenView: UIView!
    @IBOutlet weak var selectedImage: UIImageView!
    @IBOutlet weak var playImage: UIImageView!
    @IBOutlet weak var uploadingView: UIView!
    @IBOutlet weak var uploadingProgress: UIProgressView!
    @IBOutlet weak var uploadingLabel: UILabel!
    
    @objc
    func configure(with imageAsset: PHAsset?, thumbnailSize: CGFloat) {
        
        // Background color and aspect
        backgroundColor = UIColor.piwigoColorCellBackground()

        // Initialise
        cellSelected = false
        uploadingProgress.progressTintColor = UIColor.piwigoColorOrange()
        uploadingProgress.trackTintColor = UIColor.piwigoColorLeftLabel()
        uploadingLabel.font = UIFont.piwigoFontSmall()
        uploadingLabel.textColor = UIColor.piwigoColorOrangeSelected()
        uploadingLabel.text = NSLocalizedString("imageUploadTableCell_uploading", comment: "Uploading...")

        // Reduce original size of 17x25 pixels when using tiny thumbnails
        if thumbnailSize > 0.0 && thumbnailSize < 75.0 {
            let sizeOfIcon = UIImage(named: "checkMark")!.size
            let maxHeightOfIcon = thumbnailSize / 3.0
            let scale = maxHeightOfIcon / sizeOfIcon.height
            contentView.addConstraints(NSLayoutConstraint.constraintView(selectedImage, to: CGSize(width: sizeOfIcon.width * scale, height: sizeOfIcon.height * scale))!)
        }
        
        // Reduce original size of 25x16 pixels when using tiny thumbnails
        if thumbnailSize > 0.0 && thumbnailSize < 75.0 {
            let sizeOfIcon = UIImage(named: "video")!.size
            let maxWidthOfIcon = thumbnailSize / 3.0
            let scale = maxWidthOfIcon / sizeOfIcon.width
            contentView.addConstraints(NSLayoutConstraint.constraintView(playImage, to: CGSize(width: sizeOfIcon.width * scale, height: sizeOfIcon.height * scale))!)
        }
        
        // Check provided image asset
        guard let imageAsset = imageAsset else {
            self.cellImage.image = UIImage(named: "placeholder")
            return
        }

        // Prepare image
        let retinaScale = Int(UIScreen.main.scale)
        let retinaSquare = CGSize(width: thumbnailSize * CGFloat(retinaScale), height: thumbnailSize * CGFloat(retinaScale))

        let cropToSquare = PHImageRequestOptions()
        cropToSquare.resizeMode = .exact
        let cropSideLength = min(imageAsset.pixelWidth, imageAsset.pixelHeight)
        let square = CGRect(x: 0, y: 0, width: cropSideLength, height: cropSideLength)
        let cropRect = square.applying(CGAffineTransform(scaleX: CGFloat(1.0 / Float(imageAsset.pixelWidth)), y: CGFloat(1.0 / Float(imageAsset.pixelHeight))))
        cropToSquare.normalizedCropRect = cropRect

        PHImageManager.default().requestImage(for: imageAsset, targetSize: retinaSquare, contentMode: .aspectFit, options: cropToSquare, resultHandler: { result, info in
            DispatchQueue.main.async(execute: {
                if info?[PHImageErrorKey] != nil {
                    let error = info?[PHImageErrorKey] as? Error
                    if let description = error?.localizedDescription {
                        print("=> Error : \(description)")
                    }
                    self.cellImage.image = UIImage(named: "placeholder")
                } else {
                    self.cellImage.image = result
                    if imageAsset.mediaType == .video {
                        self.playImage?.isHidden = false
                    }
                }
            })
        })
    }
    
    func setProgress(_ progress: CGFloat, withAnimation animate: Bool) {
        uploadingProgress?.setProgress(Float(progress), animated: animate)
    }

    override func prepareForReuse() {
        cellImage.image = UIImage(named: "placeholder")
        cellSelected = false
        cellUploading = false
        playImage.isHidden = true
        setProgress(0, withAnimation: false)
    }
}
