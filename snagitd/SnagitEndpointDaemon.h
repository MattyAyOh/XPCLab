//
//  SnagitEndpointDaemon.h
//  TestXPCApp
//
//  Created by Matt Ao on 2/2/17.
//  Copyright © 2017 TechSmith. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSnagitEndpointMachServiceName @"com.techsmith.snagitendpointdaemon"

@protocol SnagitEndpointDaemonProtocol
- (void)checkSnagitDaemonPulse:(void(^)(BOOL))isRunning;
- (void)setSnagitHelperEndpoint:(NSXPCListenerEndpoint*)endpoint forPID:(pid_t)processID;
- (void)forSnagitHelperPID:(pid_t)processID getEndpoint:(void (^)(NSXPCListenerEndpoint *))reply;
@end

@interface SnagitEndpointDaemon : NSObject

- (id)init;
- (void)run;

@end
