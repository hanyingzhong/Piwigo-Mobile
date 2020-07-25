//
//  UploadFinisher.swift
//  piwigo
//
//  Created by Eddy Lelièvre-Berna on 01/06/2020.
//  Copyright © 2020 Piwigo.org. All rights reserved.
//

import Photos

extension UploadManager{
    
    // MARK: - Set Image Info
    func setImageParameters(with upload: UploadProperties) {
        print("    > imageOfRequest...")

        // Prepare creation date
        var creationDate = ""
        if let date = upload.creationDate {
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
            creationDate = dateFormat.string(from: date)
        }

        // Prepare parameters for uploading image/video (filename key is kPiwigoImagesUploadParamFileName)
        let imageParameters: [String : String] = [
            kPiwigoImagesUploadParamFileName: upload.fileName ?? "Image.jpg",
            kPiwigoImagesUploadParamCreationDate: creationDate,
            kPiwigoImagesUploadParamTitle: upload.imageTitle ?? "",
            kPiwigoImagesUploadParamCategory: "\(NSNumber(value: upload.category))",
            kPiwigoImagesUploadParamPrivacy: "\(NSNumber(value: upload.privacyLevel!.rawValue))",
            kPiwigoImagesUploadParamAuthor: upload.author ?? "",
            kPiwigoImagesUploadParamDescription: upload.comment ?? "",
            kPiwigoImagesUploadParamTags: upload.tagIds ?? "",
            kPiwigoImagesUploadParamMimeType: upload.mimeType ?? ""
        ]

        ImageService.setImageInfoForImageWithId(upload.imageId, withInformation: imageParameters,
            onProgress:nil,
            onCompletion: { (task, jsonData) in
    //                print("•••> completion: \(String(describing: jsonData))")
                // Check returned data
                guard let data = try? JSONSerialization.data(withJSONObject:jsonData ?? "") else {
                    // Upload still ready for finish
                    let error = NSError.init(domain: "Piwigo", code: 0, userInfo: [NSLocalizedDescriptionKey : UploadError.networkUnavailable.localizedDescription])
                    self.updateUploadRequestWith(upload, error: error)
                    return
                }
                
                // Decode the JSON.
                do {
                    // Decode the JSON into codable type ImageSetInfoJSON.
                    let uploadJSON = try self.decoder.decode(ImagesSetInfoJSON.self, from: data)
                    
                    // Piwigo error?
                    if (uploadJSON.errorCode != 0) {
                        let error = NSError.init(domain: "Piwigo", code: uploadJSON.errorCode, userInfo: [NSLocalizedDescriptionKey : uploadJSON.errorMessage])
                        self.updateUploadRequestWith(upload, error: error)
                        return
                    }

                    // Successful?
                    if uploadJSON.success {
                        // Image successfully uploaded
                        var uploadProperties = upload
                        uploadProperties.requestState = .finished
                        
                        // Will propose to delete image if wanted by user
                        if Model.sharedInstance()?.deleteImageAfterUpload == true {
                            // Retrieve image asset
                            if let imageAsset = PHAsset.fetchAssets(withLocalIdentifiers: [upload.localIdentifier], options: nil).firstObject {
                                // Only local images can be deleted
                                if imageAsset.sourceType != .typeCloudShared {
                                    // Append image to list of images to delete
                                    uploadProperties.deleteImageAfterUpload = true
                                }
                            }
                        }
                        
                        // Update upload record, cache and views
                        self.uploadsProvider.updateRecord(with: uploadProperties, completionHandler: { [unowned self] _ in
                            print("•••>> complete ;-)")
                            
                            // Any other image in upload queue?
                            self.setIsFinishing(status: false)
                        })
                    } else {
                        // Could not set image parameters, upload still ready for finish
                        print("••>> setImageInfoForImageWithId(): no successful")
                        let error = NSError.init(domain: "Piwigo", code: -1, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("serverUnknownError_message", comment: "Unexpected error encountered while calling server method with provided parameters.")])
                        self.updateUploadRequestWith(upload, error: error)
                        return
                    }
                } catch {
                    // Data cannot be digested, upload still ready for finish
                    let error = NSError.init(domain: "Piwigo", code: 0, userInfo: [NSLocalizedDescriptionKey : UploadError.wrongDataFormat.localizedDescription])
                    self.updateUploadRequestWith(upload, error: error)
                    return
                }

            },
            onFailure: { (task, error) in
                if let error = error as NSError? {
                    if ((error.code == 401) ||        // Unauthorized
                        (error.code == 403) ||        // Forbidden
                        (error.code == 404))          // Not Found
                    {
                        print("…notify kPiwigoNotificationNetworkErrorEncountered!")
                        NotificationCenter.default.post(name: NSNotification.Name(kPiwigoNotificationNetworkErrorEncountered), object: nil, userInfo: nil)
                    }
                    // Upload still ready for finish
                    self.updateUploadRequestWith(upload, error: error)
                }
            })
    }

    private func updateUploadRequestWith(_ upload: UploadProperties, error: Error?) {

        // Error?
        if let error = error {
            // Could not prepare image
            let uploadProperties = upload.update(with: .finishingError, error: error.localizedDescription)
            
            // Update request with error description
            print("    >", error.localizedDescription)
            uploadsProvider.updateRecord(with: uploadProperties, completionHandler: { [unowned self] _ in
                // Consider next image
                self.setIsFinishing(status: false)
            })
            return
        }

        // Update state of upload
        let uploadProperties = upload.update(with: .finished, error: "")

        // Update request ready for transfer
        print("    > finished with \(uploadProperties.fileName!)")
        uploadsProvider.updateRecord(with: uploadProperties, completionHandler: { [unowned self] _ in
            // Upload ready for transfer
            self.setIsFinishing(status: false)
        })
    }


    // MARK: - Community Moderation
    /**
     When the Community plugin is installed (v2.9+) on the server,
     one must inform the moderator that a number of images were uploaded.
     */
    func moderateImages(withIds imageIds: String, inCategory category: Int) {
        
        getUploadedImageStatus(byId: imageIds, inCategory: category,
            onCompletion: { (task, jsonData) in
//                    print("•••> completion: \(String(describing: jsonData))")
                
                // The following code crashes at "let decoder = JSONDecoder()" if a PNG file was uploaded !!!?
                // That is why we wimply check without decoding the JSON into codable type CommunityUploadCompletedJSON.
                guard let data = try? JSONSerialization.data(withJSONObject:jsonData ?? "") else {
                    // Will retry later
                    return
                }
                // Decode the JSON.
                do {
                    // Decode the JSON into codable type CommunityUploadCompletedJSON.
                    let decoder = JSONDecoder()
                    let uploadJSON = try decoder.decode(CommunityImagesUploadCompletedJSON.self, from: data)

                    // Piwigo error?
                    if (uploadJSON.errorCode != 0) {
                        // Will retry later
                        print("••>> moderateUploadedImages(): Piwigo error \(uploadJSON.errorCode) - \(uploadJSON.errorMessage)")
                        return
                    }

                    // Successful?
                    if uploadJSON.success {
                        // Images successfully moderated, delete them if wanted by users
                        if let completedUploads = self.uploadsProvider.requestsCompleted() {
                            let imagesToDelete = completedUploads.filter({$0.deleteImageAfterUpload == true})
                            self.delete(uploadedImages: imagesToDelete)
                        }
                    } else {
                        // Will retry later
                        print("••>> moderateUploadedImages(): no successful")
                        return
                    }
                } catch {
                    // Will retry later
                    return
                }
        }, onFailure: { (task, error) in
                // Will retry later
                return
        })
    }

    private func getUploadedImageStatus(byId imageId: String?, inCategory categoryId: Int,
            onCompletion completion: @escaping (_ task: URLSessionTask?, _ response: Any?) -> Void,
            onFailure fail: @escaping (_ task: URLSessionTask?, _ error: Error?) -> Void) -> (Void) {
        
        NetworkHandler.post(kCommunityImagesUploadCompleted,
                urlParameters: nil,
                parameters: [
                    "pwg_token": Model.sharedInstance().pwgToken!,
                    "image_id": imageId ?? "",
                    "category_id": NSNumber(value: categoryId)
                    ],
                progress: nil,
                success: completion,
                failure: fail)
    }
}
