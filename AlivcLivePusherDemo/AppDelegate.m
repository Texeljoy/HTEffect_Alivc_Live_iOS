//
//  AppDelegate.m
//  AlivcLivePusherTest
//
//  Created by lyz on 2017/10/9.
//  Copyright © 2017年 TripleL. All rights reserved.
//

#import "AppDelegate.h"
#import "AlivcNavigationController.h"
#import "AlivcRootViewController.h"
#import <AlivcLivePusher/AlivcLivePusherHeader.h>

//todo --- HTEffect start0 ---
#import <HTEffect/HTEffectInterface.h>
//todo --- HTEffect end ---

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    AlivcRootViewController *viewControllerVC = [[AlivcRootViewController alloc] init];
    AlivcNavigationController *viewControllerNC = [[AlivcNavigationController alloc] initWithRootViewController:viewControllerVC];
    self.window.rootViewController = viewControllerNC;
    
    //todo --- HTEffect start1 ---
    # error 需要HTEffect appid，与包名绑定，请联系商务获取
    [[HTEffect shareInstance] initHTEffect:@"Your AppId" withDelegate:nil];
    //todo --- HTEffect end ---
    
    [AlivcLivePusher showDebugView];
    [self.window makeKeyAndVisible];
    
    return YES;

}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
