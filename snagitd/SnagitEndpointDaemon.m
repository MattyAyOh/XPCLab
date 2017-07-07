//
//  SnagitEndpointDaemon.m
//  TestXPCApp
//
//  Created by Matt Ao on 2/2/17.
//  Copyright © 2017 TechSmith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SnagitEndpointDaemon.h"

@interface SnagitEndpointDaemon() <NSXPCListenerDelegate, SnagitEndpointDaemonProtocol>
@property NSXPCListener *daemonListener;
@property NSXPCListenerEndpoint *helperEndpoint;
@property pid_t currentHelperProcessID;
@end

@implementation SnagitEndpointDaemon

- (id)init
{
   self = [super init];
   if (self != nil) {
      self.daemonListener = [[NSXPCListener alloc] initWithMachServiceName:kSnagitEndpointMachServiceName];
      self.daemonListener.delegate = self;
   }
   return self;
}

- (void)run
{
   [self.daemonListener resume];
   [[NSRunLoop currentRunLoop] run];
}

- (void)checkSnagitDaemonPulse:(void(^)(BOOL))isRunning
{
   //Method only exists so we can detect a connection failure through a NSXPCConnnection's RemoteObjectProxy (This Daemon)
   isRunning(YES);
}

- (void)setSnagitHelperEndpoint:(NSXPCListenerEndpoint *)endpoint forPID:(pid_t)processID
{
   self.helperEndpoint = endpoint;
   self.currentHelperProcessID = processID;
}

- (void)forSnagitHelperPID:(pid_t)processID getEndpoint:(void (^)(NSXPCListenerEndpoint *))reply
{
   if( processID == self.currentHelperProcessID )
   {
      reply(self.helperEndpoint);
   }
   else
   {
      reply(nil);
   }
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
   assert(listener == self.daemonListener);
   #pragma unused(listener)
   assert(newConnection != nil);

   newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SnagitEndpointDaemonProtocol)];
   newConnection.exportedObject = self;
   [newConnection resume];

   return YES;
}

@end
