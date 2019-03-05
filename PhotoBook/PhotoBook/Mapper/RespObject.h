//
//  RespObject.h
//  TaoLeSong
//
//  Created by EmberWei on 2017/07/03.
//  Copyright © 2017年 LimeKing. All rights reserved.
//

#import "AtomObject.h"

@interface RespObject : AtomObject

// JSON 字典转化成对象
+(RespObject*)toModel:(NSDictionary*)json;

+ (void)analyseWithData:(id)data complete:(void (^)(__kindof RespObject *result, NSError *error))complete;

@end
