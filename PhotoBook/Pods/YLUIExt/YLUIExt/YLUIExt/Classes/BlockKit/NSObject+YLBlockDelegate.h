#import <Foundation/Foundation.h>

@interface NSObject (YLBlockDelegate)


+ (void)yl_linkDataSourceMethods:(NSDictionary *)selectorsForPropertyNames;


+ (void)yl_linkDelegateMethods:(NSDictionary *)selectorsForPropertyNames;


+ (void)yl_linkProtocol:(Protocol *)protocol methods:(NSDictionary *)selectorsForPropertyNames;


+ (void)yl_registerDynamicDataSource;


+ (void)yl_registerDynamicDelegate;


+ (void)yl_registerDynamicDataSourceNamed:(NSString *)dataSourceName;


+ (void)yl_registerDynamicDelegateNamed:(NSString *)delegateName;


+ (void)yl_registerDynamicDelegateNamed:(NSString *)delegateName forProtocol:(Protocol *)protocol;


- (id)yl_ensuredDynamicDelegate;


- (id)yl_ensuredDynamicDelegateForProtocol:(Protocol *)protocol;

@end
