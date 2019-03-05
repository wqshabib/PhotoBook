//
//  JsonAdapter.h
//  TaoLeSong
//
//  Created by EmberWei on 2017/07/03.
//  Copyright © 2017年 LimeKing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol JSONSerializing

@required

+ (NSDictionary *)JSONKeyPathsByPropertyKey;
+ (nullable NSDictionary *)convertClassStringDictionary;

@end

@interface JsonAdapter : NSObject

// 1.网络-> Object
+ (id)objectFromJsonData:(id)jsonData objectClass:(Class)clazz;
// 2.Object-> String
+ (NSString *)jsonStringFromObject:(id)object;
// 2.Object-> Dictionary
+ (NSDictionary *)jsonDictionaryFromObject:(id)object;

@end

NS_ASSUME_NONNULL_END
