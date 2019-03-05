#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "JsonAdapter.h"


@interface AtomObject : NSObject<NSCoding, NSCopying>

// 数组绑定
+ (nullable NSDictionary *)bridgeClassAndArray;
// 关系映射
+ (nullable NSDictionary *)bridgePropertyAndJSON;

// 载入缓存
+ (__kindof AtomObject *_Nonnull)loadCache;
// 保存
- (BOOL)saveCache;
// 清除缓存
+ (BOOL)clearCache;

// 对象转换成字典
- (NSDictionary *_Nonnull)toDict;

// 折算四舍五入
+(NSString*)round:(NSString*)price;
@end
