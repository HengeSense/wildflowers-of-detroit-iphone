//
//  AppDelegate.m
//  Wildflowers of Detroit Iphone
//
//  Created by Deep Winter on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "CameraViewController.h"
#import "MapViewController.h"
#import "RHDataModel.h"
#import "RHLocation.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize swoopTabViewController;
@synthesize loadingViewController;
@synthesize internetActive;
@synthesize internetReachable;
@synthesize networkEngine = _networkEngine;
@synthesize is4InchScreen;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.networkEngine = [[MKNetworkEngine alloc] initWithHostName:@"jrmfelipe.iriscouch.com"];
    //[self.networkEngine setPortNumber:5984];
    
    [self initializeAppDelegateAndLaunch];
    
    return true;
}


- (void) initializeAppDelegateAndLaunch {

    isDoneStartingUp = FALSE;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    //check if screen is 4inch
    is4InchScreen = NO;
    if (self.window.frame.size.height==568)
        is4InchScreen = YES;
    
    self.window.backgroundColor = [UIColor whiteColor];
    
  
    
    self.swoopTabViewController = [[SwoopTabViewController alloc] init];
    self.window.rootViewController = self.swoopTabViewController;
    
    MapViewController * galleryViewController = [[MapViewController alloc]init];
    galleryViewController.fullscreenTransitionDelegate = self.swoopTabViewController;
    galleryViewController.userDataOnly = YES;
    galleryViewController.launchInGalleryMode = YES;
    if (is4InchScreen)
    {
        [galleryViewController.view setFrame:CGRectMake(0, 0, 568, 320)];
        [galleryViewController.overlayView setFrame:CGRectMake(0, 0, 568, 320)];
    }
    self.swoopTabViewController.topViewController = galleryViewController;
    
    
    CameraViewController * cameraViewController = [[CameraViewController alloc]init];
    cameraViewController.fullscreenTransitionDelegate = self.swoopTabViewController;
    if (is4InchScreen)
    {
        [cameraViewController.view setFrame:CGRectMake(0, 0, 568, 320)];
        [cameraViewController.shutterView setFrame:CGRectMake(0, 0, 568, 320)];
        [cameraViewController.pictureInfo setFrame:CGRectMake(0, 0, 568, 320)];
        //[cameraViewController.imagePicker.view setFrame:CGRectMake(0, 0, 568, 320)];
    }
    self.swoopTabViewController.middleViewController = cameraViewController;
    
    MapViewController * mapViewController = [[MapViewController alloc]init];
    mapViewController.fullscreenTransitionDelegate = self.swoopTabViewController;
    if (is4InchScreen)
        [mapViewController.view setFrame:CGRectMake(0, 0, 568, 320)];
    self.swoopTabViewController.bottomViewController = mapViewController;
    
    
   [self.window addSubview:swoopTabViewController.view];
    self.loadingViewController = [[LoadingViewController alloc] init];
    [swoopTabViewController.view addSubview:loadingViewController.view];
    loadingViewController.loadingImageView.image = [UIImage imageNamed:@"Loading"];
    
    

    RHDataModel * dataModel =[RHDataModel instance];
    dataModel.project = @"default";
    
    // check for internet connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    
    self.internetActive = YES;
    self.internetReachable = [Reachability reachabilityForInternetConnection];
    [internetReachable startNotifier];

  //  [self performSelectorInBackground:@selector(initializeInBackground) withObject:nil];
    
    [[RHDataModel instance] initWithBlock:^{return;} ];
    
    [self.window makeKeyAndVisible];
    [self performSelector:@selector(presentApplication) withObject:nil afterDelay:3];

    
}

//Start couchBase in the background.  Calls to the datamodel will be asynchronous, allowing the database to
//start serving whenever it's ready.
- (void) removeBackersView{
    [loadingViewController.view removeFromSuperview];
    loadingViewController = nil;
    
		/*
		 * Launch Tweak
  //  @autoreleasepool {
        NSLog(@"%@", @"Starting app resources in background");
        
        //  @autoreleasepool {
        //  doing this in the background doesn't make as much sense with touchdb
        //NSLog(@"%@", @"Starting app resources in background");
        NSLog(@"%@", @"Starting app resources");    
    
        [[RHDataModel instance] initWithBlock: ^ {
            if(UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation] )){
                [loadingViewController.view removeFromSuperview];
                loadingViewController = nil;
            } else {
                
                [loadingViewController.loadingView removeFromSuperview];
                [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
                [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(receivedRotate) name: UIDeviceOrientationDidChangeNotification object: nil];
            }
            //If we are on iPhone 4, start replications
            //[[RHDataModel instance] updateSyncURL];
            
        } ];

        
        NSLog(@"%@", @"Done");

   // }
	 // */

}

- (void) delayedViewDidAppear {
    [swoopTabViewController.bottomViewController viewDidAppear:NO];
}

- (void) presentApplication {
    isDoneStartingUp = TRUE;    
    [loadingViewController.view removeFromSuperview];
    loadingViewController = nil;
    [swoopTabViewController didTouchBottomButton:self];
    if(!swoopTabViewController.manualAppearCallbacks){
        [self performSelector:@selector(delayedViewDidAppear) withObject:nil afterDelay:0.0];
    }
}

- (void) receivedRotate {
    if(UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation] ) && !isDoneStartingUp){
        [self presentApplication];
    }
}


/*
- (void(^)()) doneStartingUp {
    
    return Block_copy( ^ {
        if(UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation] )){
            
            [loadingViewController.view removeFromSuperview];
            loadingViewController = nil;
        } else {
            
            [loadingViewController.loadingView removeFromSuperview];
            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
            [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(receivedRotate) name: UIDeviceOrientationDidChangeNotification object: nil];
        }
        //  [[MapDataModel instance] updateSyncURL];
      
    });
  
}
 */




- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}


-(void) checkNetworkStatus:(NSNotification *)notice
{
    // called after network status changes
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus)
    {
        case NotReachable:
        {
            NSLog(@"The internet is down.");
            internetActive = NO;
            
            break;
        }
        case ReachableViaWiFi:
        {
            NSLog(@"The internet is working via WIFI.");
            internetActive = YES;
            
            break;
        }
        case ReachableViaWWAN:
        {
            NSLog(@"The internet is working via WWAN.");
            internetActive = YES;
            
            break;
        }
    }
}


- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)w {
        UIViewController *topController = self.window.rootViewController;
        if( [topController supportedInterfaceOrientations]!=0)
        {
            return [w.rootViewController supportedInterfaceOrientations];
        }
        return UIInterfaceOrientationMaskAll;
}

@end
