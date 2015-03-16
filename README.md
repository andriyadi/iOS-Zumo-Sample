# iOS-Zumo-Sample
iOS (Swift) + Microsoft Azure Mobile Services sample. Shows how to customise default Get Start sample (Todo app) by adding authentication and post image

In `ToDoTableViewController` class, you'll find:

``client = MSClient(applicationURLString: "YOUR_MOBILE_SERVICES_URL", applicationKey: "YOUR_MOBILE_SERVICES_KEY")``

Make sure to change `YOUR_MOBILE_SERVICES_URL` and `YOUR_MOBILE_SERVICES_KEY` with your own Azure Mobile Services configuration.

I use this code to do the demo during my talk along with this slide: [http://www.slideshare.net/andri_yadi/endtoend-mobile-app-development-with-ios-and-azure-mobile-services](http://www.slideshare.net/andri_yadi/endtoend-mobile-app-development-with-ios-and-azure-mobile-services)

On server side, you need to add this script on `INSERT` operation of `TodoUser` table:

```javascript
function insert(item, user, request) {

    var usersTable = tables.getTable('TodoUser');

    usersTable.where({
        userId: user.userId,
    }).read({
        success: function(results) {
            if (results.length == 0) {
                insertNewUser(usersTable, user);
            }
            else {
                console.log('User exists');
                request.respond(statusCodes.OK, results[0]);
            }
        }
    });
    
    function insertNewUser(theUserTable, theUser) {
        
        theUser.getIdentities({
            success: function (identities) {
                //request.respond(200, identities);
                if (identities.twitter) {
                    var newUser = {
                        userId: theUser.userId,                        
                    };
                    if (identities.twitter.screen_name) {
                        newUser.username = identities.twitter.screen_name;
                    }
                    console.log(identities);
                    
                    theUserTable.insert(newUser, {
                        success: function(newItem) {
                            // Write to the response now that all data operations are complete
                            console.log('A new user is registered');
                            request.respond(statusCodes.OK, newItem);
                        }
                    });
                } 
                else {
                    console.log('Identities is failed. ' + identities);
                    request.respond();
                }               
            }
        });
    }
}
```