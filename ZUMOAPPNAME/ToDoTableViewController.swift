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

class ToDoTableViewController: UITableViewController, ToDoItemDelegate {
    
    var client: MSClient?
    var records = [NSMutableDictionary]()
    private lazy var imageCache: NSMutableDictionary = NSMutableDictionary(capacity: 10)
    var table : MSTable?
    var viewDidAppearOnce = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        client = MSClient(applicationURLString: "YOUR_MOBILE_SERVICES_URL", applicationKey: "YOUR_MOBILE_SERVICES_KEY")
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (viewDidAppearOnce) {
            return
        }
        
        viewDidAppearOnce = true
        
        //check token
        if let currentUserId = NSUserDefaults.standardUserDefaults().objectForKey("MOBILE_SERVICE_USER_ID") as? String {
            client?.currentUser = MSUser(userId: currentUserId)
            client?.currentUser.mobileServiceAuthenticationToken = NSUserDefaults.standardUserDefaults().objectForKey("MOBILE_SERVICE_TOKEN") as? String
        }
        
        if let currUser = client?.currentUser {
            refresh();
        }
        else {
            client?.loginWithProvider("twitter", controller:self, animated:true) {
                //trailing closure for completion handler
                (user, error) -> Void in
                if user != nil {
                    self.didSignedInWithUser(user)
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!)
    {
        if segue.identifier == "addItem" {
            let todoController = segue.destinationViewController as ToDoItemViewController
            todoController.delegate = self
            todoController.client = self.client
        }
    }

    
    func didSignedInWithUser(user: MSUser) {
        //save user token
        NSUserDefaults.standardUserDefaults().setObject(user.userId, forKey: "MOBILE_SERVICE_USER_ID")
        NSUserDefaults.standardUserDefaults().setObject(user.mobileServiceAuthenticationToken, forKey: "MOBILE_SERVICE_TOKEN")
        
        self.refresh()
        
        //register auth-ed user
        registerSignedInUser(user)
    }
    
    func registerSignedInUser(user: MSUser) {
        let userTable = client?.tableWithName("TodoUser")
        userTable?.insert(["userId": user.userId]){
            (item, error) in
            if let err = error {
                println("Error: " + err.description)
            }
        }
    }
    
    func refresh() {
        //self.table = client?.tableWithName("TodoItem")!
        self.table = client?.tableWithName("UserTodoItem")!
        self.refreshControl?.addTarget(self, action: "onRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        
        self.refreshControl?.beginRefreshing()
        self.onRefresh(self.refreshControl)
    }
    
    func onRefresh(sender: UIRefreshControl!) {
        let predicate = NSPredicate(format: "complete == NO && user == %@", self.client!.currentUser.userId)
        
        let query = self.table?.queryWithPredicate(predicate)
        query?.includeTotalCount = true
        query?.selectFields = ["id", "text", "complete"]
        
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        //self.table!.readWithPredicate(predicate) {
        
        query?.readWithCompletion {
            
            result, totalCount, error  in
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if error != nil {
                println("Error: " + error.description)
                
                let alert = UIAlertController(title: "Oppss...", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
                alert.addAction(action)
                self.presentViewController(alert, animated: true, completion: nil)
                
                return
            }
            
            self.records = result as [NSMutableDictionary]
            println("Information: retrieved %d records", result.count)
            
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Table
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle
    {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String!
    {
        return "Complete"
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        let record = self.records[indexPath.row]
        let completedItem = record.mutableCopy() as NSMutableDictionary
        completedItem["complete"] = true
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        self.table!.update(completedItem) {
            (result, error) in
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if error != nil {
                println("Error: " + error.description)
                return
            }
            
            self.records.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.records.count
    }
    
    func loadImageForIndexPath(indexPath: NSIndexPath) {
        let record = self.records[indexPath.row]
        let recordId = record["id"] as String!
        
        if let image = self.imageCache[recordId] as? UIImage {
            
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
                cell.imageView?.image = image
            }
        }
        else {
            
            let predicate = NSPredicate(format: "id == %@", record["id"] as String!)
            let query = self.table?.queryWithPredicate(predicate)
            
            weak var wself: ToDoTableViewController? = self
            
            query?.fetchLimit = 1
            query?.selectFields = ["photo"]
            query?.readWithCompletion({ (results, recordCount, error) -> Void in
                if results.count > 0 {
                    if let cell = wself?.tableView.cellForRowAtIndexPath(indexPath) {
                        
                        if let imageBase64 = results[0]["photo"] as? String {
                            //let imageBase64 = results[0]["photo"] as String
                            record["photo"] = imageBase64
                            let imageData = NSData(base64EncodedString: imageBase64, options: NSDataBase64DecodingOptions())!
                            let image = UIImage(data: imageData)
                            
                            self.imageCache[recordId] = image
                            
                            cell.imageView?.image = image
                            cell.setNeedsLayout()
                        }
                    }
                }
            })
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let CellIdentifier = "Cell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath) as UITableViewCell
        let item = self.records[indexPath.row]
        
        cell.textLabel?.text = item["text"] as? String
        cell.textLabel?.textColor = UIColor.blackColor()
        
        loadImageForIndexPath(indexPath)
        
        return cell
    }
    
    // Navigation
    
    @IBAction func addItem(sender : AnyObject) {
        self.performSegueWithIdentifier("addItem", sender: self)
    }
    
    @IBAction func unwindFromItemForm(segue: UIStoryboardSegue?) {
        
    }
    
    // ToDoItemDelegate

    func didSaveItem(text: String, assigneeId: String, photo: UIImage?, completion: (NSError?, NSDictionary?) -> Void)
    {
        if text.isEmpty {
            return
        }
        
        
        let userId = self.client!.currentUser.userId
        var itemToInsert:Dictionary<String, AnyObject> = ["text": text, "assigneeId": assigneeId, "complete": false, "user": self.client!.currentUser.userId]
        
        //Experimental, put image photo as Base64 string
        if let thePhoto = photo {
            let photoData = UIImageJPEGRepresentation(thePhoto, 0.9)
            let photoBase64 = photoData.base64EncodedStringWithOptions(nil)
            itemToInsert["photo"] = photoBase64
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        self.table!.insert(itemToInsert) {
            (item, error) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.dismissViewControllerAnimated(true, completion: nil);
            
            if error != nil {
                println("Error: " + error.description)
                completion(error, nil)
                
            } else {
                let newItem = NSMutableDictionary(dictionary: item)
                self.records.append(newItem)
                self.tableView.reloadData()
                
                completion(nil, newItem)
            }           
            
        }
    }
}
