// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit
import MobileCoreServices

protocol ToDoItemDelegate {
    func didSaveItem(text : String, assigneeId: String, photo: UIImage?, completion: (NSError?, NSDictionary?) -> Void)
}

class ToDoItemViewController: UIViewController, UINavigationBarDelegate,  UIBarPositioningDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AutocompleteTextFieldDelegate {
    
    @IBOutlet var NavBar : UINavigationBar!
    @IBOutlet var text : UITextField!
    @IBOutlet weak var asigneeTextView: AutocompleteTextfield!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var loadingActivity: UIActivityIndicatorView!
    
    var selectedImage: UIImage?
    var delegate : ToDoItemDelegate?
    
    var client: MSClient?
    var userTable: MSTable?
    
    var lastUserQueryResuls = [String: NSDictionary]()
    var assigneeId: String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.NavBar.delegate = self
        self.text.delegate = self
        self.text.becomeFirstResponder()
        
        if let c = self.client {
            self.userTable = c.tableWithName("TodoUser")
        }
        
        asigneeTextView.autoCompleteDelegate = self
        asigneeTextView.hideWhenSelected = true
        asigneeTextView.hideWhenEmpty = true
        asigneeTextView.autoCompleteTextColor = UIColor.lightGrayColor()
        asigneeTextView.autoCompleteTextFont = UIFont(name: "HelveticaNeue-Light", size: 12.0)
        asigneeTextView.autoCompleteCellHeight = 35.0
        asigneeTextView.maximumAutoCompleteCount = 3
        
        asigneeTextView.enableAttributedText = true
        var attributes = Dictionary<String,AnyObject>()
        attributes[NSForegroundColorAttributeName] = UIColor.blackColor()
        attributes[NSFontAttributeName] = UIFont(name: "HelveticaNeue-Bold", size: 12.0)
        asigneeTextView.autoCompleteAttributes = attributes
    }
    
    // MARK: - AutocompleteTextFieldDelegate methods
    
    func didSelectAutocompleteText(text:String, indexPath:NSIndexPath) {
        if let userDict = self.lastUserQueryResuls[self.asigneeTextView!.text] {
            self.assigneeId = userDict["userId"] as? String
        }
        
    }
    
    func autoCompleteTextFieldDidChange(text:String) {
        if let theUserTable = self.userTable {
            let pred = NSPredicate(format: "username CONTAINS[cd] %@", text)
            let query = theUserTable.queryWithPredicate(pred)
            
            query.readWithCompletion{
                result, count, err in
                
                var names = [String]()
                
                for userDict in result as [NSDictionary]{
                    let uname = userDict["username"] as String
                    names.append(uname)
                    self.lastUserQueryResuls[uname] = userDict
                }
                
                self.asigneeTextView.autoCompleteStrings = names
            }
        }
        else {
            self.asigneeTextView.autoCompleteStrings = []
        }
    }
    
    // MARK: - action methods
    
    @IBAction func takePhoto(sender: UIButton) {
        
        weak var wself: ToDoItemViewController? = self
        
        let actionSheet = UIAlertController(title: "Photo from...", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
        
            let action1 = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.choosePhotoFromSource(UIImagePickerControllerSourceType.Camera)
            })
            
            actionSheet.addAction(action1)
        }
        
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary)) {
            
            let action1 = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                wself!.choosePhotoFromSource(UIImagePickerControllerSourceType.PhotoLibrary)
            })
            
            actionSheet.addAction(action1)
        }
        
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum)) {
            
            let action1 = UIAlertAction(title: "Saved Album", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                wself!.choosePhotoFromSource(UIImagePickerControllerSourceType.SavedPhotosAlbum)
            })
            
            actionSheet.addAction(action1)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        self.presentViewController(actionSheet, animated: true) { () -> Void in
        }
        
    }
    
    @IBAction func cancelPressed(sender : UIBarButtonItem) {
        self.text.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func savePressed(sender : UIBarButtonItem) {
        saveItem()
        self.text.resignFirstResponder()
    }
    
    // MARK: - private methods and some delegates
    
    func choosePhotoFromSource(source: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = source
        imagePicker.mediaTypes = [kUTTypeImage!]
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        self.presentViewController(imagePicker, animated: true, completion: { () -> Void in
            
        })
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        
        self.selectedImage = image //editingInfo[UIImagePickerControllerEditedImage] as? UIImage
        self.selectedImageView.image = self.selectedImage
        self.takePhotoButton.hidden = true
        
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    
    func positionForBar(bar: UIBarPositioning!) -> UIBarPosition
    {
        return UIBarPosition.TopAttached
    }
    
    // Textfield
    
    func textFieldDidEndEditing(textField: UITextField!)
    {
        //self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func textFieldShouldEndEditing(textField: UITextField!) -> Bool
    {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool
    {
        saveItem()
        
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - ToDoItemDelegate method
    
    func saveItem()
    {        
        self.loadingActivity.startAnimating()
        let text = self.text.text
        
        self.delegate?.didSaveItem(text, assigneeId: self.assigneeId!, photo: self.selectedImage, completion: {
            (err, item) in
            self.performSegueWithIdentifier("backToTaskList", sender: nil)
        });
        
    }
}