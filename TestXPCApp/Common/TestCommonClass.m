//
//  TestCommonClass.m
//  TestXPCApp
//
//  Created by Matt Ao on 2/7/17.
//  Copyright © 2017 TechSmith. All rights reserved.
//

#import "TestCommonClass.h"

@implementation TestCommonClass

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
   self = [super init];
   if (!self) {
      return nil;
   }

//   self.testString = [aDecoder decodeObjectForKey:@"testStringKey"];
   self.testString = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"testStringKey"];
   return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
   [aCoder encodeObject:self.testString forKey:@"testStringKey"];
}

+ (BOOL)supportsSecureCoding
{
   return YES;
}

@end
