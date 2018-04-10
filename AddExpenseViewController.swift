//
//  AddExpenseViewController.swift
//  MECARS
//
//  Created by Chinnu M V on 11/2/17.
//  Copyright © 2017 citrus.applicationsatest. All rights reserved.
//

import UIKit
import ReachabilitySwift
import AWSS3
import AWSCore
import Photos
import AssetsLibrary
import MobileCoreServices
import OpalImagePicker


class AddExpenseViewController: UIViewController,UIPickerViewDelegate,UIPickerViewDataSource,UIImagePickerControllerDelegate,
UINavigationControllerDelegate,OpalImagePickerControllerDelegate,UITextFieldDelegate {
    
    @IBOutlet weak var operatorTypeSelectTextField: UITextField!
    @IBOutlet weak var operatorTypeTextField: UITextField!
    @IBOutlet weak var feesTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    let database = DataBase()
    
     let imagePicker = OpalImagePickerController()
    var isEditMode : Bool!
    var trip_elaboration_id : String!
    var trip_elaboration_note : String!
    var selectedpickOption : String!
    var selectedpickOptionOther : String!
    let webservicehandler = WebServiceHandler();
    
    var pickOption = ["Parking Fee", "Toll Fees", "Others" ]
    var pickOptionValue = [ "1", "2", "3" ]
    
    var pickOptionOther = ["Airfare", "Meals", "Car rental", "Entertainment" , "Gas", "Taxi", "Public Transport"]
    var pickOptionValueOther = ["4", "5", "3", "10" , "12" , "19" , "23" ]
    
    
    var locationId : Int64!
    var activityId : String!
    var tripID : String!
     var tripUUID : String!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var trip_details:NSDictionary!
    let reachability = Reachability()!
    var syncData = SyncData()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        imagePickerInit()
        let btn1 = UIButton(type: .system)
        btn1.setTitle("Save", for: .normal)
        btn1.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
        btn1.addTarget(self, action: #selector(AddExpenseViewController.saveButtonPressed), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: btn1)
        self.navigationItem.setRightBarButtonItems([item1], animated: true)
        operatorTypeSelectTextField.delegate = self
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.tag = 101
        operatorTypeSelectTextField.inputView = pickerView
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        
        let result = formatter.string(from: date)
        
        dateLabel.text = result
        
        self.title = "Add Expense"
        if isEditMode == true
        {
            self.title = "Edit Expense"
            let dictValues = self.convertToDictionary(text: trip_details.value(forKey: "elaboration_data") as! String)
            print(dictValues)
            dateLabel.text=dictValues!["date"] as? String
            operatorTypeSelectTextField.text=trip_details.value(forKey: "label") as! String
            feesTextField.text=dictValues!["fee"] as? String
            locationTextField.text=dictValues!["locationName"] as? String
            tripUUID = "\(trip_details.value(forKey: "elaboration_uuid")!)"
            
            operatorTypeTextField.text = dictValues!["operator"] as? String
            if operatorTypeTextField.text == "parking Fee"{
                selectedpickOption = "1"
            }
            else{
                selectedpickOption = "2"
            }
        }
        
        
        picker.delegate = self
        
        
    }
    
    
    func imagePickerInit(){
        
        imagePicker.selectionTintColor = UIColor.white.withAlphaComponent(0.7)
        
        //Change color of image tint to black
        imagePicker.selectionImageTintColor = UIColor.black
        
        //Change image to X rather than checkmark
        imagePicker.selectionImage = UIImage(named: "x_image")
        
        //Change status bar style
        imagePicker.statusBarPreference = UIStatusBarStyle.lightContent
        
        //Limit maximum allowed selections to 5
        imagePicker.maximumSelectionsAllowed = 5
        
        //Only allow image media type assets
       // imagePicker.allowedMediaTypes = Set([PHAssetMediaType.image])
        
        //Change default localized strings displayed to the user
        let configuration = OpalImagePickerConfiguration()
        configuration.maximumSelectionsAllowedMessage = NSLocalizedString("You can only select 5 photos at a time.", comment: "")
        imagePicker.configuration = configuration
        
        
    }
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let viewControllers = self.navigationController?.viewControllers {
            let previousVC: UIViewController? = viewControllers.count >= 2 ? viewControllers[viewControllers.count - 2] : nil; // get previous view
            previousVC?.title = ""
        }
    }
    
    @objc func saveButtonPressed( )  {
        
         var UUIDVal = UUID().uuidString
        
        //   "operator":"Ekn","fee":"209","billImageUUID":["2aca1570-c464-11e7-b479-f5bcdb260943"],"locationName":"Uuiii","date":"11/8/2017","description":"","companyPaid":"No"}
        if (self.operatorTypeSelectTextField.text?.isEmpty)! {
            appDelegate.showAlertMessage(controller: self, title: "MECARS", message: "Select an operator.");
            return;
        }
        if (feesTextField.text?.isEmpty)! {
            appDelegate.showAlertMessage(controller: self, title: "MECARS", message: "Please enter amount");
            return;
        }
        if self.appDelegate.currentLocationlatitude == nil {
            appDelegate.showAlertMessage(controller: self, title: "Error", message: "Location not availble .");
            return;
        }
        
        if selectedpickOption == "3" {
            
            if (operatorTypeTextField.text?.isEmpty)!{
                appDelegate.showAlertMessage(controller: self, title: "MECARS", message: "Please select a type.");
                
                return;
            }
            
        }
        locationId  = database.addLocationData(latitude: "\(appDelegate.currentLocationlatitude!)", latitude_text: "\(appDelegate.currentLocationlatitude!)", longitude: "\(appDelegate.currentLocationlongitude!)", longitude_text: "\(appDelegate.currentLocationlongitude!)", location_name: "", location_type_id:  "8000" , accuracy: "\(appDelegate.getCurrentLocationAccuracy())")
        
        var theJSONTextValue : String = ""
        let date = Date()
        
        
        
        
        
        let dict = NSMutableDictionary()
        dict.setValue(operatorTypeTextField.text!, forKey: "operator")
        dict.setValue(feesTextField.text!, forKey: "fee")
        dict.setValue(imageNames, forKey: "billImageUUID")
        dict.setValue(locationTextField.text!, forKey: "locationName")
        dict.setValue(dateLabel.text!, forKey: "date")
        dict.setValue("", forKey: "description")
        dict.setValue("No", forKey: "companyPaid")
        if let theJSONData = try?  JSONSerialization.data(
            withJSONObject: dict,
            options: .prettyPrinted
            ),
            let theJSONText = String(data: theJSONData,
                                     encoding: String.Encoding.ascii) {
            print("JSON string = \n\(theJSONText)")
            theJSONTextValue = theJSONText
            
            
        }
        
        
        var elaboration_type_id = "0";
        if  selectedpickOption == "3"{
            elaboration_type_id = "\(selectedpickOptionOther!)"
        }
        else{
            elaboration_type_id = "\(selectedpickOption!)"
        }
          var pIDValEla : Int64 = 0
        if isEditMode == true{
            
           
            
            
            
            deleteElaborationData(id: "\(trip_elaboration_id!)", uuid: "\(tripUUID!)", typeid: "\(elaboration_type_id)")
            
            database.deleteTrip_elaborationData(Notes_id: "\(trip_elaboration_id!)")
            
            
          //  database.UpdateDataInTripElaboration(trip_elaboration_id: "\(trip_elaboration_id!)", activity_id: activityId, elaboration_uuid: UUID().uuidString, elaboration_type_id: elaboration_type_id, label: operatorTypeSelectTextField.text!, elaboration_data: "\(theJSONTextValue)", location_id: "\(locationId!)", created_at: "\(date)", is_deleted: "0", elaboration_category_id: "1")
   
            
            
            
            
        }
            
            
        else{
   
        }
        
        pIDValEla = database.insertDataInTripElaboration(activity_id: activityId, elaboration_uuid: UUID().uuidString, elaboration_type_id: selectedpickOption!, label: operatorTypeSelectTextField.text!, elaboration_data: "\(theJSONTextValue)", location_id: "\(locationId!)", created_at: "\(date)", is_deleted: "0", elaboration_category_id: "1")
        
        
        
        
        
        
        var cost = 0.0
        var tripCost = database.getTripTotalCost(trip_id: "\(activityId!)")
        
        if(tripCost.count>0){
            
            let dict  = tripCost.object(at: 0) as! NSDictionary
            
            let val = dict.value(forKey: "Cost")!
            cost =  val as! Double
        }
        let userid = UserDefaults.standard.value(forKey:  "userID")!
        cost = cost + Double(feesTextField.text!)!
        
        database.updateTripCost(trip_id: activityId, cost: "\(cost)")
        var pIDVal : Int64 = 0
        if self.reachability.currentReachabilityStatus == .notReachable{
            
            let pID =  database.addParentLoginActivity(parent: "\(activityId!)", level: "1", activity: "Add parking fee", activityTypeID: "500", remarks: "", startDate: "\(date)", endDate: "\(date)", startLocationID: "\(locationId!)", selectedStartLocationID: "\(locationId!)", completedLocationID: "\(locationId!)", selectedcompletedLocationID: "\(locationId!)", parentName: "",sync_immediate: "0",sync_immediate_status: "", userID: "\(userid)")
            self.database.updateparentTripLogs(activity_id: "\(activityId!)")
            pIDVal = pID
        }
            
        else{
            
            let pID =  database.addParentLoginActivity(parent: "\(activityId!)", level: "1", activity: "Add parking fee", activityTypeID: "500", remarks: "", startDate: "\(date)", endDate: "\(date)", startLocationID: "\(locationId!)", selectedStartLocationID: "\(locationId!)", completedLocationID: "\(locationId!)", selectedcompletedLocationID: "\(locationId!)", parentName: "",sync_immediate: "1",sync_immediate_status: "OK", userID: "\(userid)")
            
            syncData.jsonDataCreatiionWithTripId(trip_ID: "\(pID)", session_ID: UserDefaults.standard.value(forKey: "sessionID") as! String)
            syncData.jsonDataCreatiionWithTripId(trip_ID: "\(activityId!)", session_ID: UserDefaults.standard.value(forKey: "sessionID") as! String)
            pIDVal = pID
        }
        
        
        
        
        
        if imageUrls.count > 0 {
            
            
            self.database.deleteTrip_elaborationDataActivityId(act_id: activityId!)
            
            
            for i in 0 ... imageUrls.count-1{
                
                var name = imageNames[i];
                var imgUrl = imageUrls[i];
                
            var theJSONTextValueimage : String = ""
            
            let date = Date()
          
                
                
            let dictVal = NSMutableDictionary()
            dictVal.setValue("\(name).jpg", forKey: "fileName")
            dictVal.setValue("\(date)", forKey: "date")
            dictVal.setValue(TimeZone.current.identifier, forKey: "timezone")
            
            if let theJSONData = try?  JSONSerialization.data(
                withJSONObject: dictVal,
                options: .prettyPrinted
                ),
                let theJSONText = String(data: theJSONData,
                                         encoding: String.Encoding.ascii) {
                print("JSON string = \n\(theJSONText)")
                theJSONTextValueimage = theJSONText
                print(theJSONTextValueimage)
                
                
            }
            
            var   media_uuid = ""
            let dictmedia_uuid = NSMutableDictionary()
            dictVal.setValue( name, forKey: "media_uuid")
            
            if let theJSONData = try?  JSONSerialization.data(
                withJSONObject: dictmedia_uuid,
                options: .prettyPrinted
                ),
                let theJSONText = String(data: theJSONData,
                                         encoding: String.Encoding.ascii) {
                print("JSON string = \n\(theJSONText)")
                media_uuid = theJSONText
                
                
                
            }
            
            
                let pID =  database.addParentLoginActivity(parent: "\(pIDVal)", level: "1", activity: "Trip::Trip Media Streaming Started", activityTypeID: "513", remarks: media_uuid, startDate: "\(date)", endDate: "\(date)", startLocationID: "\(locationId!)", selectedStartLocationID: "\(locationId!)", completedLocationID: "\(locationId!)", selectedcompletedLocationID: "\(locationId!)", parentName: "",sync_immediate: "0",sync_immediate_status: "", userID: "\(userid)")
              //   syncData.jsonDataCreatiionWithTripId(trip_ID: "\(pID)", session_ID: UserDefaults.standard.value(forKey: "sessionID") as! String)

            let pIDTrip = database.insertDataInTripElaboration(activity_id: "\(activityId!)", elaboration_uuid: name, elaboration_type_id: "26", label: "Image Capture", elaboration_data: "\(theJSONTextValueimage)", location_id: "\(locationId!)", created_at: "\(date)", is_deleted: "0", elaboration_category_id: "4")
            database.insertDataInTripElaborationAudioSync(activity_id: "\(activityId!)", trip_id: "\(tripID!)", elaboration_uuid: name, mediafilepath: "\(imgUrl)", syncstatus: "Not Started", fileName: "\(name).jpg", aws_s3_fileName: "\(name).jpg", mediaType: "image", recordType: "", recordCustomerName: "", recordTypeOfCall: "")
            
            
          self.syncData.jsonDataCreatiionWithTripId(trip_ID: "\(pID)", session_ID: UserDefaults.standard.value(forKey: "sessionID") as! String)
            print(imageUrls[i])
                uploadFile(uuidVal: name,idval: "\(pIDVal)", imageURL: imageUrls[i])
           
            syncData.jsonDataCreatiionWithTripId(trip_ID: "\(activityId!)", session_ID: UserDefaults.standard.value(forKey: "sessionID") as! String)
        }
        }
        
        
        
        
        
        // image uploading
        
        
        
        
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
        // self.appDelegate.showAlertMessage(controller: self, title: "Information", message: "Expense added successfuly.")
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (operatorTypeSelectTextField.text?.isEmpty)!{
            
            if textField == operatorTypeSelectTextField{
                
                operatorTypeSelectTextField.text = "Parking Fee"
             selectedpickOption = pickOptionValue[0]
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    // MARK: - PickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 101 {
            return pickOption.count
        }
        return pickOptionOther.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView.tag == 101 {
            return pickOption[row]
        }
        return pickOptionOther[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView.tag == 101{
            operatorTypeSelectTextField.text = pickOption[row]
            selectedpickOption = pickOptionValue[row]
          //  selectedpickOptionOther = pickOptionValueOther[row]
            
            if selectedpickOption == "3" {
                let pickerView = UIPickerView()
                pickerView.delegate = self
                pickerView.dataSource = self
                pickerView.tag = 100
                operatorTypeTextField.inputView = pickerView
                // feesTextField.alpha = 0.0
                locationTextField.alpha = 0.0
                operatorTypeTextField.placeholder = "Select a type"
                
            }
            else{
                operatorTypeTextField.inputView = nil
                // feesTextField.alpha = 1.0
                locationTextField.alpha = 1.0
                operatorTypeTextField.placeholder = "Operator name"
            }
        }
        else{
            
            operatorTypeTextField.text = pickOptionOther[row]
            selectedpickOptionOther = pickOptionValueOther[row]
        }
    }
    
    
    
    // Image uploading to AWS
    
    
    
    func   getAWSCredentials()
    {
        webservicehandler.gettingDictionaryFromServer_GET(urlString: "\(ENTERPRISE_APP_BASE_URL)\(ENTERPRISE_SERVICE_URL_AWS_S3_CREDENTIALS)", paramters: nil, callback: { (dict) in
            print(dict)
            if dict.value(forKey: "JsonData") != nil {
                DispatchQueue.main.async {
                    
                    
                    let  AccountID = dict.value(forKey: "AccountID") as! String
                    let  BucketName = dict.value(forKey: "BucketName") as! String
                    let  Destination = dict.value(forKey: "Destination") as! String
                    let  RoleARN = dict.value(forKey: "RoleARN") as! String
                    let  PoolID = dict.value(forKey: "PoolID") as! String
                    //   self.ConfigAWS(accessKey: AccountID , secretKey: PoolID, S3BucketName: BucketName, poolID: PoolID)
                }
            }
            
        });
    }
    
    var AWS_DIRECTORY_AUDIO =  "audioRecordings";
    var AWS_DIRECTORY_IMAGE =  "capturedImages/";
    
    func uploadFile(uuidVal:String,idval:String ,imageURL : URL){
        var S3BucketName = "mecarstripaudio"
        var poolID="us-east-1:300ebc69-fb0f-4d07-ab93-9b770513c0c3"
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,                                                               identityPoolId:poolID)
        
        
        let configuration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        imageName="\(uuidVal).jpg"
        print(imageName)
        let url = imageURL
        let remoteName = imageName!
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()!
        uploadRequest.body = url
        print("\(AWS_DIRECTORY_IMAGE)\(imageName!)")
        uploadRequest.key = "\(AWS_DIRECTORY_IMAGE)\(imageName!)"
        uploadRequest.bucket = S3BucketName
        uploadRequest.contentType = "image/jpeg"
        uploadRequest.acl = .publicRead
        let transferManager = AWSS3TransferManager.default()
        self.database.TripElaborationAudioSync(aws_s3_fileName: imageName, status: "Started")
        transferManager.upload(uploadRequest).continueWith { (task: AWSTask) -> Any? in
            if let error = task.error {
                print("Upload failed with error: (\(error.localizedDescription))")
                print("Upload failed with error: (\(task.error))")
                self.database.TripElaborationAudioSync(aws_s3_fileName: "\(uuidVal).jpg", status: "Failed")
            }
            if task.result != nil {
                print(task.result)
                self.database.TripElaborationAudioSync(aws_s3_fileName: "\(uuidVal).jpg", status: "Completed")
                let url = AWSS3.default().configuration.endpoint.url
                let publicURL = url?.appendingPathComponent(uploadRequest.bucket!).appendingPathComponent(uploadRequest.key!)
                 print("uploadRequest.key! to:\(uploadRequest.key!)")
                print("Uploaded to:\(publicURL)")
         
                var  locationIdImage  = self.database.addLocationData(latitude: "\(self.appDelegate.currentLocationlatitude!)", latitude_text: "\(self.appDelegate.currentLocationlatitude!)", longitude: "\(self.appDelegate.currentLocationlongitude!)", longitude_text: "\(self.appDelegate.currentLocationlongitude!)", location_name: "", location_type_id:  "8000" , accuracy: "\(self.appDelegate.getCurrentLocationAccuracy())")
                
                
                
                let userid = UserDefaults.standard.value(forKey:  "userID")!
                let date = Date()
            var   media_uuid = ""
                let dictVal = NSMutableDictionary()
                dictVal.setValue( uuidVal, forKey: "media_uuid")
              
                if let theJSONData = try?  JSONSerialization.data(
                    withJSONObject: dictVal,
                    options: .prettyPrinted
                    ),
                    let theJSONText = String(data: theJSONData,
                                             encoding: String.Encoding.ascii) {
                    print("JSON string = \n\(theJSONText)")
                    media_uuid = theJSONText
                    
                    
                    
                }
                
                
                
                
                let pID =  self.database.addParentLoginActivity(parent: "\(idval)", level: "1", activity: "Trip::Trip Media Streaming Completed", activityTypeID: "516", remarks: media_uuid, startDate: "\(date)", endDate: "\(date)", startLocationID: "\(locationIdImage)", selectedStartLocationID: "\(locationIdImage)", completedLocationID: "\(locationIdImage)", selectedcompletedLocationID: "\(locationIdImage)", parentName: "",sync_immediate: "0",sync_immediate_status: "", userID: "\(userid)")
                self.syncData.jsonDataCreatiionWithTripId(trip_ID: "\(pID)", session_ID: UserDefaults.standard.value(forKey: "sessionID") as! String)
self.syncData.jsonDataCreatiionWithTripId(trip_ID: "\(self.activityId!)", session_ID: UserDefaults.standard.value(forKey: "sessionID") as! String)
            
                
//                ManageTripViewController().uploadsArray = self.database.getUploads(activity_id: self.activityId)
//                ManageTripViewController().tripTableView.reloadData()
                
            }
            
            return nil
        }
        
        
        
    }
    var customView : ImageSelectionPopup!
    var blurEffectView : UIVisualEffectView!
    
    @IBAction func imageUploadingPressed(_ sender: Any) {
        
        self.view.endEditing(true)
        self.view.resignFirstResponder()
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView!.isUserInteractionEnabled = true
        blurEffectView.alpha = 0.8
        blurEffectView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AddExpenseViewController.removeLocationView)))
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            blurEffectView!.frame = self.view.bounds
            self.view.addSubview(blurEffectView!)
        }else {
            self.view.backgroundColor = UIColor.black
        }
        customView = ImageSelectionPopup().loadNib() as! ImageSelectionPopup
        
        customView.frame = CGRect(x:self.view.frame.size.width/2 - 150, y:self.view.frame.size.height/2 - 150, width:300, height:300)
        
        customView.cameraButton.addTarget(self, action: #selector(AddExpenseViewController.CameraButtonPressed), for: .touchUpInside)
        
        
        customView.galleryButton.addTarget(self, action: #selector(AddExpenseViewController.GalleryButtonPressed), for: .touchUpInside)
        
        customView.closeButton.addTarget(self, action: #selector(AddExpenseViewController.CloseButtonPressed), for: .touchUpInside)
        self.view.addSubview(customView)
        
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        });
        
        
    }
    @objc func CameraButtonPressed( ) {
        
        picker.allowsEditing = false
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String]
     //   picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)!
        present(picker, animated: true, completion: nil)
    }
    
    @objc func GalleryButtonPressed( ) {
        
        
       
        imagePicker.imagePickerDelegate = self
//        presentOpalImagePickerController(imagePicker, animated: true,
//                                         select: { (images) in
//                                            print(images)
//                                            self.presentedViewController?.dismiss(animated: true, completion: {
//                                                self.CloseButtonPressed()
//                                            })
//                                            //Select Assets
//        }, cancel: {
//            //Cancel
//        })
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String]
     //  imagePicker = UIImagePickerController.availableMediaTypes(for: .camera)!
        present(imagePicker, animated: true, completion: nil)
    }
    @objc func CloseButtonPressed( ) {
        removeLocationView()
        
    }
    @objc func removeLocationView()
    {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion:{(finished : Bool)  in
            if (finished)
            {
                self.customView.removeFromSuperview()
                self.blurEffectView!.removeFromSuperview()
            }
        });
        
        
    }
    let picker = UIImagePickerController()
    var imageUrl : URL!
    var imageName : String!
    
    //MARK: - Add image to Library
    
    func fileInDocumentsDirectory(filename: String) -> String {
        let documentsFolderPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString
        return documentsFolderPath.appendingPathComponent(filename)
    }
    
    func saveImage(image: UIImage, path: String ) {
        let pngImageData = UIImagePNGRepresentation(image)
        
        do {
            try pngImageData?.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            print(error)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage //2
        
        print(chosenImage)
      
        
        
        
        
        
        if picker.sourceType == .camera
        {

            
            if var image = info[UIImagePickerControllerOriginalImage] as? UIImage {// image asset
                
                
                let orientationFixedImage = image.fixOrientation()
                self.saveImage(image: orientationFixedImage, path: fileInDocumentsDirectory(filename: "temp_dummy_image.png"))
                
                imageUrl = URL(fileURLWithPath: fileInDocumentsDirectory(filename: "temp_dummy_image.png"))
                imageName = "temp_dummy_image.png"
                self.imageUrls.append(imageUrl as URL)
                self.imageNames.append(UUID().uuidString)
                
            }
            
            
            
            
        }
        else
        {

        if #available(iOS 11.0, *) {
            imageUrl = info[UIImagePickerControllerImageURL] as! URL
               print(imageUrl)
        } else {
            // Fallback on earlier versions
        }
        //




        if let imageURL = info[UIImagePickerControllerReferenceURL] as? NSURL {
            print(imageURL)
            let result = PHAsset.fetchAssets(withALAssetURLs: [imageURL as URL], options: nil)
           imageName =  result.firstObject?.burstIdentifier

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",
                                                             ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                                 PHAssetMediaType.image.rawValue,
                                                 PHAssetMediaType.video.rawValue)
            fetchOptions.fetchLimit = 100

            PHAsset.fetchAssets(with: fetchOptions)
            let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)


        }
        }
        self.removeLocationView()
        
        dismiss(animated:true, completion: nil) //5
        
    }
    
   
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        
        self.removeLocationView()
    }
 var imageNames = [String]()
  var imageUrls = [URL]()
    
    var documentsUrl: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    private func save(image: UIImage, fileName : String) -> URL? {
        
        let fileURL = documentsUrl.appendingPathComponent(fileName)
        if let imageData = UIImageJPEGRepresentation(image, 1.0) {
            try? imageData.write(to: fileURL, options: .atomic)
            return fileURL // ----> Save fileName
        }
        print("Error saving image")
        return nil
    }
    
    

    
    

    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingImages images: [UIImage]) {
       
          for i in 0...images.count-1{
            
            var filename=UUID().uuidString
            var strURL =   self.save(image: images[i], fileName: filename+".jpg")!
            self.imageUrls.append(strURL as URL)
            self.imageNames.append(filename)
            
        }
        dismiss(animated: true, completion: nil)
        removeLocationView()
    }
    
    func deleteElaborationData(id:String,uuid:String,typeid:String){
        
        
        
        let  paramDictionary =  NSMutableDictionary();
        
        paramDictionary.setValue(typeid, forKey: "elaboration_type_Id")
        paramDictionary.setValue(uuid, forKey: "elaboration_uuid")
        var session = UserDefaults.standard.value(forKey: "sessionID")
        paramDictionary.setValue( "\(session!)", forKey: "session_id")
        
        
        
        
        webservicehandler.gettingDictionaryFromServer_POST(urlString: "\(ENTERPRISE_APP_BASE_URL)\(ENTERPRISE_SERVICE_URL_REMOVE_ELABORATION_DATA)", paramters: paramDictionary, callback: { (dict) in
            print(dict)
            print(dict.value(forKey: "status"))
            if dict.value(forKey: "status") == nil {
                DispatchQueue.main.async {
                    
                    self.appDelegate.showAlertMessage(controller: self, title: "Error", message: " Failed")
                }
            }
            if  dict.value(forKey: "status") as! String == "1" {
                DispatchQueue.main.async {
                    
                  
                    self.appDelegate.showAlertMessage(controller: self, title: "Message!", message: dict.value(forKey: "statusMessage") as! String)
                }
                
            }
            else
            {
                DispatchQueue.main.async {
                    
                    self.appDelegate.removeLoadingIndicator()
                    self.appDelegate.showAlertMessage(controller: self, title: "Message!", message: dict.value(forKey: "statusMessage") as! String);
                    
                   
                    
                    
                    
                    
                }}
        });
    }
    
    
}

extension UIImage {
    func fixOrientation() -> UIImage {
        if self.imageOrientation == UIImageOrientation.up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        if let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return normalizedImage
        } else {
            return self
        }
    }
}
