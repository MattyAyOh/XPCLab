//
//  TestXPCService.h
//  TestXPCService
//
//  Created by Matt Ao on 1/27/17.
//  Copyright © 2017 TechSmith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestXPCServiceProtocol.h"
#import "TestProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface TestXPCService : NSObject
@end
