//
//  AppDelegate.m
//  TestXPCApp
//
//  Created by Matt Ao on 1/27/17.
//  Copyright © 2017 TechSmith. All rights reserved.
//

#import "AppDelegate.h"
#import "TestProtocol.h"
#import "SnagitEndpointDaemon.h"
#include <ServiceManagement/ServiceManagement.h>
#import "TestCommonClass.h"

@interface AppDelegate () {
   AuthorizationRef _authRef;
}

@property (weak) IBOutlet NSWindow *window;
@property NSXPCConnection *snagitHelperConnection;
@property NSXPCConnection *snagitDaemonConnection;
@property NSXPCConnection *anonymousConnection;
@property NSXPCListenerEndpoint *helperEndpoint;
@end

@implementation AppDelegate

- (IBAction)testing:(id)sender
{
   [[self.snagitHelperConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError){
      NSLog(@"%@", proxyError);
   }] logHelper];

   [[self.snagitHelperConnection remoteObjectProxy] getPreInitializedCustomObject:^(TestCommonClass *object) {
      NSLog(@"HERE: %@", object.testString);
   }];

   TestCommonClass *testObject = [TestCommonClass new];
   testObject.testString = @"CONSTRUCTED IN MAIN APP";
   [[self.snagitHelperConnection remoteObjectProxy] setCustomObject:testObject];

   [[self.snagitHelperConnection remoteObjectProxy] getCustomObject:^(TestCommonClass *object) {
      NSLog(@"CONSTRUCTED: %@", object.testString);
   }];
}

- (IBAction)establishConnection:(id)sender
{
   assert([NSThread isMainThread]);
   if (self.snagitHelperConnection == nil && self.helperEndpoint) {
      self.snagitHelperConnection = [[NSXPCConnection alloc] initWithListenerEndpoint:self.helperEndpoint];
      self.snagitHelperConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProtocol)];

      self.snagitHelperConnection.interruptionHandler = ^{
         NSLog(@"Connection Terminated");
      };

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
      // We can ignore the retain cycle warning because a) the retain taken by the
      // invalidation handler block is released by us setting it to nil when the block
      // actually runs, and b) the retain taken by the block passed to -addOperationWithBlock:
      // will be released when that operation completes and the operation itself is deallocated
      // (notably self does not have a reference to the NSBlockOperation).
      self.snagitHelperConnection.invalidationHandler = ^{
         NSLog(@"INVALIDATE");

         // If the connection gets invalidated then, on the main thread, nil out our
         // reference to it.  This ensures that we attempt to rebuild it the next time around.
         self.snagitHelperConnection.invalidationHandler = nil;
         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.snagitHelperConnection = nil;
         }];
      };
#pragma clang diagnostic pop
      [self.snagitHelperConnection resume];
   }
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
   [self.snagitDaemonConnection invalidate];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   [self connectToDaemon];
}

- (void)connectToDaemon
{
   assert([NSThread isMainThread]);
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

   [self launchDaemonIfItIsNotRunning];
}

- (void)launchDaemonIfItIsNotRunning
{
   if( self.snagitDaemonConnection )
   {
      __weak id weakSelf = self;
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         [[self.snagitDaemonConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
            NSLog(@"DAEMON ISN'T RUNNING: %@", error);
            self.snagitDaemonConnection = nil;
            [weakSelf launchDaemon];
         }] checkSnagitDaemonPulse:^(BOOL isRunning) {
            NSLog(@"DAEMON IS RUNNING!");
            [weakSelf launchHelper];
         }];
      }];
   }
}

- (void)launchDaemon
{
   OSStatus                    err;
   AuthorizationExternalForm   extForm;

   err = AuthorizationCreate(NULL, NULL, 0, &self->_authRef);
   if (err == errAuthorizationSuccess) {
      err = AuthorizationMakeExternalForm(self->_authRef, &extForm);
   }
   if (err == errAuthorizationSuccess) {
      NSLog(@"SUCCESS AUTHORIZING DAEMON");
   }

   Boolean             success2;
   CFErrorRef          error2;
   success2 = SMJobBless(
                         kSMDomainSystemLaunchd,
                         CFSTR("com.techsmith.snagitendpointdaemon"),
                         self->_authRef,
                         &error2
                         );

   if( success2 ) {
      NSLog(@"SUCCESSFULLY LAUNCHED DAEMON");
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         [self connectToDaemon];
      }];
   }
   else {
      NSLog(@"FAILED TO LAUNCH DAEMON");
   }
}


- (void)launchHelper;
{
   NSError* error2 = nil;
   NSURL* url = [[NSBundle mainBundle] bundleURL];
   url = [url URLByAppendingPathComponent:@"Contents" isDirectory:YES];
   url = [url URLByAppendingPathComponent:@"MacOS" isDirectory:YES];
   url = [url URLByAppendingPathComponent:@"TestHelperXPC.app" isDirectory:YES];

   [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url
                                                 options:NSWorkspaceLaunchWithoutActivation
                                           configuration:[NSDictionary dictionary]
                                                   error:&error2];

   if ( error2 )
   {
      NSLog(@"launchApplicationAtURL:%@ error = %@", url, error2);
      [[NSAlert alertWithError:error2] runModal];
   }

   [self getHelperEndpointFromDaemon];
}

- (void)getHelperEndpointFromDaemon
{
   __weak id weakSelf = self;
   if( self.snagitDaemonConnection )
   {
      NSRunningApplication* runningCapHelper;

      runningCapHelper = [[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.TechSmith.TestHelperXPC"] firstObject];

      [[self.snagitDaemonConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
         NSLog(@"ERROR: %@", error);
         [weakSelf launchDaemon];
      }] forSnagitHelperPID:runningCapHelper.processIdentifier getEndpoint:^(NSXPCListenerEndpoint *endpoint) {
         NSLog(@"GOT IT!: %@", endpoint);
         if( endpoint )
         {
            self.helperEndpoint = endpoint;
         }
         else
         {
            [weakSelf getHelperEndpointFromDaemon];
         }
      }];
   }
   else
   {
      NSLog(@"DAEMON CONNECTION NOT INITIALIZED");
   }
}




@end
