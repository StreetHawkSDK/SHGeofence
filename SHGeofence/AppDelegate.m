//
//  AppDelegate.m
//  SHGeofence
//
//  Created by Christine on 6/22/16.
//  Copyright © 2016 StreetHawk. All rights reserved.
//

#import "AppDelegate.h"
#import <StreetHawkCore/StreetHawkCore.h>

@interface AppDelegate ()

- (void)geofenceEnterExitHandler:(NSNotification *)notification;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [StreetHawk registerInstallForApp:@"SHGeofence" withDebugMode:YES];
 
    //Get notified when enter/exit a server defined geofence.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(geofenceEnterExitHandler:) name:SHLMEnterExitGeofenceNotification object:nil];
    
    return YES;
}

- (void)geofenceEnterExitHandler:(NSNotification *)notification
{
    NSDictionary *geofence = notification.userInfo;
    //It contains many property for compare: latitude, longitude, radius, title, suid etc. I use "title" in this demo as it's easy to read.
    NSString *title = geofence[@"title"];
    BOOL isInside = [geofence[@"isInside"] boolValue];
    if (isInside) //means enter a geofence, register delay local notification with matching information.
    {
        [StreetHawk feed:0 withHandler:^(NSArray *arrayFeeds, NSError *error) //fetch feed json
        {
            for (SHFeedObject *feedObj in arrayFeeds)
            {
                NSDictionary *json = feedObj.content;
                if ([title compare:json[@"title"]] == NSOrderedSame)  //find the match feed json, you can define your own compare condition, using latitude, longitude, radius, title or suid etc.
                {
                    NSString *title = feedObj.title;
                    NSString *message = feedObj.message;
                    double delayMins = [json[@"delay"] doubleValue]; //feed can add customized value such as delay time
                    //create delay fire local notification
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertTitle = title;
                    localNotification.alertBody = message;
                    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:delayMins * 60]; //delay fire
                    localNotification.soundName = UILocalNotificationDefaultSoundName;
                    localNotification.applicationIconBadgeNumber = 1;
                    localNotification.userInfo = @{@"title": title};
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                    break;
                }
            }
        }];
    }
    else //means exit a geofence, cancel the not fired local notification.
    {
        for (UILocalNotification *localNotification in [UIApplication sharedApplication].scheduledLocalNotifications)
        {
            if ([title compare:localNotification.userInfo[@"title"]] == NSOrderedSame)
            {
                [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
            }
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
