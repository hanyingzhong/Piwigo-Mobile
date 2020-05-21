//
//  LocalImagesHeaderReusableView.swift
//  piwigo
//
//  Created by Eddy Lelièvre-Berna on 18/02/2019.
//  Copyright © 2019 Piwigo.org. All rights reserved.
//
//  Converted to Swift 5.1 by Eddy Lelièvre-Berna on 13/04/2020
//

import Photos
import UIKit

@objc protocol LocalImagesHeaderDelegate: NSObjectProtocol {
    func didSelectImagesOfSection(_ section: Int)
}

@objc
class LocalImagesHeaderReusableView: UICollectionReusableView {
    
    @objc enum SelectButtonState : Int {
        case none
        case select
        case deselect
    }

    private var location: CLLocation = CLLocation.init()
    private var dateLabelText: String = ""
    private var optionalDateLabelText: String = ""

    // MARK: - View
    
    @objc weak var headerDelegate: LocalImagesHeaderDelegate?
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var placeLabel: UILabel!

    @objc
    func configure(with images: [PHAsset], section: Int, selectState: SelectButtonState) {
        
        // General settings
        backgroundColor = UIColor.piwigoColorBackground().withAlphaComponent(0.75)

        // Keep section for future use
        self.section = section
        
        // Data label used when place name known
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.numberOfLines = 1
        dateLabel.adjustsFontSizeToFitWidth = false
        dateLabel.font = UIFont.piwigoFontSmall()
        dateLabel.textColor = UIColor.piwigoColorRightLabel()

        // Place name of location
        placeLabel.translatesAutoresizingMaskIntoConstraints = false
        placeLabel.numberOfLines = 1
        placeLabel.adjustsFontSizeToFitWidth = false
        placeLabel.font = UIFont.piwigoFontSemiBold()
        placeLabel.textColor = UIColor.piwigoColorLeftLabel()

        // Get date labels from images in section
        let labels = getDateLabels(of: images)
        dateLabelText = labels[0]
        optionalDateLabelText = labels[1]

        // Determine location from images in section
        location = getLocation(of: images)
        
        // Set up labels from dates and place name
        setLabelsFromDatesAndLocation()

        // Select/deselect button
        tintColor = UIColor.piwigoColorOrange()
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor.piwigoColorOrange(),
            NSAttributedString.Key.font: UIFont.piwigoFontNormal()
        ]
        let title:String
        switch selectState {
        case .select:
            title = NSLocalizedString("categoryImageList_selectButton", comment: "Select")
        case .deselect:
            title = NSLocalizedString("categoryImageList_deselectButton", comment: "Deselect")
        case.none:
            title = ""
        }
        let buttonTitle = NSAttributedString(string: title, attributes: attributes)
        selectButton.setAttributedTitle(buttonTitle, for: .normal)
    }

    private var section = 0

    @IBAction func tappedSelectButton(_ sender: Any) {
        if headerDelegate?.responds(to: #selector(LocalImagesHeaderDelegate.didSelectImagesOfSection(_:))) ?? false {
            // Select/deselect section of images
            headerDelegate?.didSelectImagesOfSection(section)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        dateLabel.text = ""
        placeLabel.text = ""
    }

    // MARK: Utilities
    
    @objc private func setLabelsFromDatesAndLocation() {
        // Get place name from location (will geodecode location for future use if needed)
        let placeNames = LocationsProvider.sharedInstance().getPlaceName(for: location)

        // Use label according to name availabilities
        if let placeLabelName = placeNames["placeLabel"] as? String {
            placeLabel.text = placeLabelName
            if let dateLabelName = placeNames["dateLabel"] as? String {
                self.dateLabel.text = String(format: "%@ • %@", dateLabelText, dateLabelName)
            } else {
                self.dateLabel.text = String(format: "%@ • %@", dateLabelText, optionalDateLabelText)
            }
        } else {
            placeLabel.text = dateLabelText
            dateLabel.text = optionalDateLabelText
        }
    }
    
    private func getDateLabels(of images: [PHAsset]) -> [String] {
        // Creation date of images (or of availability)
        var imageAsset = images.first
        var dateLabelText = ""
        var optionalDateLabelText = ""

        // Determine if images of this section were all taken today
        if let dateCreated1 = imageAsset?.creationDate {
            
            // Display date of day by default, will add time in the absence of location data
            dateLabelText = DateFormatter.localizedString(from: dateCreated1, dateStyle: .long, timeStyle: .none)
            optionalDateLabelText = DateFormatter.localizedString(from: dateCreated1, dateStyle: .none, timeStyle: .long)
            
            // Get creation date of last image
            imageAsset = images.last
            if let dateCreated2 = imageAsset?.creationDate {
                
                // Set dates in right order in case user sorted images in reverse order
                let firstImageDate = (dateCreated1 < dateCreated2) ? dateCreated1 : dateCreated2
                let lastImageDate = (dateCreated1 > dateCreated2) ? dateCreated1 : dateCreated2
                let firstImageDay = Calendar.current.dateComponents([.year, .month, .day], from: firstImageDate)
                let lastImageDay = Calendar.current.dateComponents([.year, .month, .day], from: lastImageDate)

                // Images taken the same day?
                if firstImageDay == lastImageDay {
                    // Images were taken the same day
                    // => Keep dataLabel as already set and define optional string with starting and ending times
                    let firstImageDateStr = DateFormatter.localizedString(from: firstImageDate, dateStyle: .none, timeStyle: .short)
                    let lastImageDateStr = DateFormatter.localizedString(from: lastImageDate, dateStyle: .none, timeStyle: .short)
                    if (firstImageDateStr == lastImageDateStr) {
                        optionalDateLabelText = firstImageDateStr
                    } else {
                        optionalDateLabelText = "\(firstImageDateStr) - \(lastImageDateStr)"
                    }
                } else {
                    // => Images not taken the same day, same month?
                    let firstImageMonth = Calendar.current.dateComponents([.year, .month], from: firstImageDate)
                    let lastImageMonth = Calendar.current.dateComponents([.year, .month], from: lastImageDate)
                    if (firstImageMonth == lastImageMonth) {
                        // Images taken during the sme month
                        // => Display month instead of dates
                        let dateFormatter = DateFormatter.init()
                        dateFormatter.locale = .current
                        dateFormatter.setLocalizedDateFormatFromTemplate("MMMMYYYY")
                        dateLabelText = dateFormatter.string(from: dateCreated1)
                        // Define optional string with days
                        if UIScreen.main.bounds.size.width > 414 {
                            // i.e. larger than iPhones 6, 7 screen width
                            dateFormatter.setLocalizedDateFormatFromTemplate("EEEE d HH:mm")
                            optionalDateLabelText = dateFormatter.string(from: dateCreated1) + " — " + dateFormatter.string(from: dateCreated2)
                        } else {
                            dateFormatter.setLocalizedDateFormatFromTemplate("EEEE d")
                            optionalDateLabelText = dateFormatter.string(from: dateCreated1) + " — " + dateFormatter.string(from: dateCreated2)
                        }
                    } else  {
                        // => Will display starting and ending dates
                        // See https://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
                        let dateFormatter = DateFormatter.init()
                        dateFormatter.locale = .current
                        if UIScreen.main.bounds.size.width > 414 {
                            // i.e. larger than iPhones 6, 7 screen width
                            dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd")
                            dateLabelText = dateFormatter.string(from: dateCreated1) + " — " + dateFormatter.string(from: dateCreated2)
                        } else {
                            dateFormatter.setLocalizedDateFormatFromTemplate("MMd")
                            dateLabelText = dateFormatter.string(from: dateCreated1) + " — " + dateFormatter.string(from: dateCreated2)
                        }
                        // Define optional string with year
                        dateFormatter.setLocalizedDateFormatFromTemplate("YYYY")
                        let firstYear = dateFormatter.string(from: dateCreated1)
                        optionalDateLabelText = firstYear
                    }
                }
            }
        }
        return [dateLabelText, optionalDateLabelText]
    }
    
    private func getLocation(of images: [PHAsset]) -> CLLocation {
        // Initialise location of section with invalid location
        var locationForSection = CLLocation.init(coordinate: kCLLocationCoordinate2DInvalid,
                                                 altitude: CLLocationDistance(0.0),
                                                 horizontalAccuracy: CLLocationAccuracy(0.0),
                                                 verticalAccuracy: CLLocationAccuracy(0.0),
                                                 timestamp: Date())

        // Loop over images in section
        for imageAsset in images {

            // Any location data ?
            guard let assetLocation = imageAsset.location else {
                // Image has no valid location data => Next image
                continue
            }

            // Location found => Store if first found and move to next section
            if !CLLocationCoordinate2DIsValid(locationForSection.coordinate) {
                // First valid location => Store it
                locationForSection = assetLocation
            } else {
                // Another valid location => Compare to first one
                let distance = locationForSection.distance(from: assetLocation)
                if distance <= locationForSection.horizontalAccuracy {
                    // Same location within horizontal accuracy
                    continue
                }
                // Still a similar location?
                let meanLatitude: CLLocationDegrees = (locationForSection.coordinate.latitude + assetLocation.coordinate.latitude)/2
                let meanLongitude: CLLocationDegrees = (locationForSection.coordinate.longitude + assetLocation.coordinate.longitude)/2
                let newCoordinate = CLLocationCoordinate2DMake(meanLatitude,meanLongitude)
                var newHorizontalAccuracy = kCLLocationAccuracyBestForNavigation
                let newVerticalAccuracy = max(locationForSection.verticalAccuracy, assetLocation.verticalAccuracy)
                if distance < kCLLocationAccuracyBest {
                    newHorizontalAccuracy = max(kCLLocationAccuracyBest, locationForSection.horizontalAccuracy)
                    locationForSection = CLLocation(coordinate: newCoordinate, altitude: locationForSection.altitude,
                                                    horizontalAccuracy: newHorizontalAccuracy, verticalAccuracy: newVerticalAccuracy,
                                                    timestamp: locationForSection.timestamp)
                    return locationForSection
                } else if distance < kCLLocationAccuracyNearestTenMeters {
                    newHorizontalAccuracy = max(kCLLocationAccuracyNearestTenMeters, locationForSection.horizontalAccuracy)
                    locationForSection = CLLocation(coordinate: newCoordinate, altitude: locationForSection.altitude,
                                                    horizontalAccuracy: newHorizontalAccuracy, verticalAccuracy: newVerticalAccuracy,
                                                    timestamp: locationForSection.timestamp)
                    return locationForSection
                } else if distance < kCLLocationAccuracyHundredMeters {
                    newHorizontalAccuracy = max(kCLLocationAccuracyHundredMeters, locationForSection.horizontalAccuracy)
                    locationForSection = CLLocation(coordinate: newCoordinate, altitude: locationForSection.altitude,
                                                    horizontalAccuracy: newHorizontalAccuracy, verticalAccuracy: newVerticalAccuracy,
                                                    timestamp: locationForSection.timestamp)
                    return locationForSection
                } else if distance < kCLLocationAccuracyKilometer {
                    newHorizontalAccuracy = max(kCLLocationAccuracyKilometer, locationForSection.horizontalAccuracy)
                    locationForSection = CLLocation(coordinate: newCoordinate, altitude: locationForSection.altitude,
                                                    horizontalAccuracy: newHorizontalAccuracy, verticalAccuracy: newVerticalAccuracy,
                                                    timestamp: locationForSection.timestamp)
                    return locationForSection
                } else if distance < kCLLocationAccuracyThreeKilometers {
                    newHorizontalAccuracy = max(kCLLocationAccuracyThreeKilometers, locationForSection.horizontalAccuracy)
                    locationForSection = CLLocation(coordinate: newCoordinate, altitude: locationForSection.altitude,
                                                    horizontalAccuracy: newHorizontalAccuracy, verticalAccuracy: newVerticalAccuracy,
                                                    timestamp: locationForSection.timestamp)
                    return locationForSection
                } else {
                    // Above 3 km, we estimate that it is a different location
                    return locationForSection
                }
             }
        }
        
        return locationForSection
    }
}
