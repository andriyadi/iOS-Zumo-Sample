# iOS-Zumo-Sample
iOS (Swift) + Microsoft Azure Mobile Services sample. Shows how to customise default Get Start sample (Todo app) by adding authentication and post image

In ```ToDoTableViewController``` class, you'll find:

``client = MSClient(applicationURLString: "YOUR_MOBILE_SERVICES_URL", applicationKey: "YOUR_MOBILE_SERVICES_KEY")``

Make sure to change ```YOUR_MOBILE_SERVICES_URL``` and ```YOUR_MOBILE_SERVICES_KEY``` with your own Azure Mobile Services configuration.

I use this code to do the demo during my talk along with this slide: [http://www.slideshare.net/andri_yadi/endtoend-mobile-app-development-with-ios-and-azure-mobile-services](http://)
