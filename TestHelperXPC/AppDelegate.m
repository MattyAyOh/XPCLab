//
//  AppDelegate.m
//  TestHelperXPC
//
//  Created by Matt Ao on 1/27/17.
//  Copyright © 2017 TechSmith. All rights reserved.
//

#import "AppDelegate.h"
#import "TestProtocol.h"
#import "SnagitEndpointDaemon.h"
#import "TestCommonClass.h"

@interface AppDelegate () <NSXPCListenerDelegate, HelperProtocol>

@property (weak) IBOutlet NSWindow *window;
@property NSXPCConnection *snagitDaemonConnection;
@property TestCommonClass *helperCustomObject;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   NSLog(@"HELPER LAUNCHING");
   NSXPCListener *anonymousListener = [NSXPCListener anonymousListener];
   anonymousListener.delegate = self;
   [anonymousListener resume];


   self.snagitDaemonConnection = [[NSXPCConnection alloc] initWithMachServiceName:kSnagitEndpointMachServiceName options:NSXPCConnectionPrivileged];
   self.snagitDaemonConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SnagitEndpointDaemonProtocol)];
   self.snagitDaemonConnection.invalidationHandler = ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
      self.snagitDaemonConnection.invalidationHandler = nil;
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         self.snagitDaemonConnection = nil;
         NSLog(@"CONNECTION INVALIDATED");
      }];
   };
   self.snagitDaemonConnection.interruptionHandler = ^{
      NSLog(@"INTERRUIPTED CONNECTION!");
   };
#pragma clang diagnostic pop
   [self.snagitDaemonConnection resume];

   NSLog(@"SETTING LISTENER FROM HELPER: %d", [NSProcessInfo processInfo].processIdentifier);
   if( self.snagitDaemonConnection )
   {
      [[self.snagitDaemonConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
         NSLog(@"ERROR CONNECTING");
         NSLog(@"ERROR: %@", error);
      }] setSnagitHelperEndpoint:anonymousListener.endpoint forPID:[NSProcessInfo processInfo].processIdentifier];
   }
   else
   {
      NSLog(@"DAEMON CONNECTION NOT INITIALIZED");
   }
}

- (void)logHelper
{
   NSLog(@"LOGGING HELPER!");
}

- (void)getCustomObject:(void (^)(TestCommonClass *))reply
{
   reply(self.helperCustomObject);
}

- (void)setCustomObject:(TestCommonClass *)object
{
   self.helperCustomObject = object;
}

- (void)getPreInitializedCustomObject:(void (^)(TestCommonClass *))reply
{
   TestCommonClass *preInitializedObject = [TestCommonClass new];
   preInitializedObject.testString = @"PREINITIALIZEDSTRING!";
   reply(preInitializedObject);
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
// Called by our XPC listener when a new connection comes in.  We configure the connection
// with our protocol and ourselves as the main object.
{
   NSLog(@"LISTENING");
#pragma unused(listener)
   assert(newConnection != nil);

   newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProtocol)];
   newConnection.exportedObject = self;
   [newConnection resume];

   return YES;
}

- (void)testMethod
{
   NSLog(@"HEY");
}

- (void)testXPCMethod:(void(^)(NSString * version))reply
{
   reply(@"REPLY");
}
@end
