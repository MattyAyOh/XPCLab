//
//  main.m
//  snagitd
//
//  Created by Matt Ao on 2/2/17.
//  Copyright © 2017 TechSmith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SnagitEndpointDaemon.h"

int main(int argc, const char * argv[]) {
   @autoreleasepool {
      SnagitEndpointDaemon *d;
      d = [[SnagitEndpointDaemon alloc] init];
      [d run];
   }
    return EXIT_FAILURE;
}
