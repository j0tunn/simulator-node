//
//  main.cpp
//  simulator-node
//
//  Created by Anton Usmanskiy on 10/16/15.
//  Copyright © 2015 jotunn. All rights reserved.
//

#include <iostream>
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBSimulatorControl/FBSimulatorControl+Private.h>
#import <FBSimulatorControl/FBSimulatorControlConfiguration.h>
#import <FBSimulatorControl/FBSimulatorApplication.h>
#import <FBSimulatorControl/FBSimulatorConfiguration.h>
#import <FBSimulatorControl/FBProcessLaunchConfiguration.h>
#import <FBSimulatorControl/FBSimulatorSession.h>
#import <FBSimulatorControl/FBSimulatorSessionInteraction.h>
#import <FBSimulatorControl/FBSimulatorPool.h>
#import <FBSimulatorControl/FBSimulator.h>


int main(int argc, const char * argv[]) {
    FBSimulatorManagementOptions managementOptions = FBSimulatorManagementOptionsDeleteManagedSimulatorsOnFirstStart |
         FBSimulatorManagementOptionsKillUnmanagedSimulatorsOnFirstStart |
         FBSimulatorManagementOptionsDeleteOnFree;

    FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
        configurationWithSimulatorApplication:[FBSimulatorApplication simulatorApplicationWithError:nil]
        deviceSetPath:nil
        namePrefix:nil
        bucket:0
        options:managementOptions];

    FBSimulatorControl *control = [[FBSimulatorControl alloc] initWithConfiguration:configuration];

    NSError *error = nil;
    FBSimulatorSession *session = [control createSessionForSimulatorConfiguration:FBSimulatorConfiguration.iPhone5 error:&error];
    FBSimulatorSession *session2 = [control createSessionForSimulatorConfiguration:FBSimulatorConfiguration.iPhone5 error:&error];

    FBApplicationLaunchConfiguration *appLaunch = [FBApplicationLaunchConfiguration
        configurationWithApplication:[FBSimulatorApplication systemApplicationNamed:@"MobileSafari"]
        arguments:@[]
        environment:@{}];

    [[[session.interact
        bootSimulator]
        launchApplication:appLaunch]
        performInteractionWithError:&error];

    NSLog(@"simulator: %@", session.simulator.udid);
    NSLog(@"simulator2: %@", session2.simulator.udid);

    [[[session2.interact
        bootSimulator]
        launchApplication:appLaunch]
        performInteractionWithError:&error];

    __block BOOL keepRunning = YES;
    
    // Configure a dispatch source to listen for SIGTERM
    // Adapted from https://mikeash.com/pyblog/friday-qa-2011-04-01-signal-handling.html
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGTERM, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(source, ^{
        printf("SIGTERM received!\n");
        keepRunning = NO;
    });
    dispatch_resume(source);

    source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGINT, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(source, ^{
        printf("SIGINT received!\n");
        keepRunning = NO;
    });
    dispatch_resume(source);
    
    // Tell sigaction to ignore SIGTERM - it's handled by the dispatch source above
    struct sigaction action = {0};
    action.sa_handler = SIG_IGN;
    sigaction(SIGTERM, &action, NULL);
    sigaction(SIGINT, &action, NULL);
    
    // Main run loop
    @autoreleasepool {
        NSLog(@"Hello, world!");
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        do {
            @autoreleasepool {
                [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        } while (keepRunning);
    }

    [control.simulatorPool killManagedSimulatorsWithError:nil];
    return 0;
}
