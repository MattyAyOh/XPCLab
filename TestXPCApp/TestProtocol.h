//
//  TestProtocol.h
//  TestXPCApp
//
//  Created by Matt Ao on 1/27/17.
//  Copyright © 2017 TechSmith. All rights reserved.
//

#ifndef TestProtocol_h
#define TestProtocol_h
#import "TestCommonClass.h"

@protocol TestProtocol <NSObject>

- (void)testMethod;
- (void)testXPCMethod:(void(^)(NSString *version))reply;
- (void)setAnonymousEndpoint:(NSXPCListenerEndpoint*)endpoint;
- (void)getAnonymousEndpoint:(void(^)(NSXPCListenerEndpoint *endpoint))reply;

@end

@protocol HelperProtocol <NSObject>

- (void)logHelper;
- (void)setCustomObject:(TestCommonClass*)object;
- (void)getCustomObject:(void(^)(TestCommonClass *object))reply;
- (void)getPreInitializedCustomObject:(void(^)(TestCommonClass *object))reply;

@end
#endif /* TestProtocol_h */
