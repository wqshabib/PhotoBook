//
//  RespObject.m
//  TaoLeSong
//
//  Created by EmberWei on 2017/07/03.
//  Copyright © 2017年 LimeKing. All rights reserved.
//

#import "RespObject.h"

@implementation RespObject

+ (void)analyseWithData:(id)data complete:(void (^)(__kindof RespObject *result, NSError *errMor))complete {
    
    __kindof RespObject *result = [JsonAdapter objectFromJsonData:data objectClass:[self class]];
    if (!result) {
        if (complete) {
            complete(nil, [NSError errorWithDomain:@"服务器返回非JSON格式字符" code:400 userInfo:nil]);
        }
        return;
    }
    if (complete) {
        complete(result,nil);
    }
}

+(RespObject*)toModel:(NSDictionary*)json
{
    __kindof RespObject *result = [JsonAdapter objectFromJsonData:json objectClass:[self class]];
    if (!result) {
        return [[RespObject alloc] init];
    }
    return result;
}

@end
