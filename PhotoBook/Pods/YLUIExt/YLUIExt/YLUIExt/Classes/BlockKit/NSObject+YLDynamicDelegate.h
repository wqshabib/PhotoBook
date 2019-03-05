//
//  NSObject+EBDynamicDelegate.h
//  EmberKit
//
//  Created by Ember on 2017/8/11.
//  Copyright © 2017年 Ember. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YLBlockDelegate.h"

@interface NSObject (YLDynamicDelegate)

- (id)yl_dynamicDataSource;

- (id)yl_dynamicDelegate;

- (id)yl_dynamicDelegateForProtocol:(Protocol *)protocol;

@end
