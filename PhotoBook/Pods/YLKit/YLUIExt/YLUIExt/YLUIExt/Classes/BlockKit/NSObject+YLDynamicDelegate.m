#import <objc/runtime.h>
#import "NSObject+YLDynamicDelegate.h"
#import "NSObject+YLBlockDelegate.h"

extern Protocol *yl_dataSourceProtocol(Class cls);
extern Protocol *yl_delegateProtocol(Class cls);

static Class yl_dynamicDelegateClass(Class cls, NSString *suffix)
{
    while (cls) {
        NSString *className = [NSString stringWithFormat:@"A2Dynamic%@%@", NSStringFromClass(cls), suffix];
        Class ddClass = NSClassFromString(className);
        if (ddClass) return ddClass;
        
        cls = class_getSuperclass(cls);
    }
    
    return [YLBlockDelegate class];
}

static dispatch_queue_t yl_backgroundQueue(void)
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t backgroundQueue = nil;
    dispatch_once(&onceToken, ^{
        backgroundQueue = dispatch_queue_create("BlocksKit.DynamicDelegate.Queue", DISPATCH_QUEUE_SERIAL);
    });
    return backgroundQueue;
}

@implementation NSObject (YLDynamicDelegate)

- (id)yl_dynamicDataSource
{
    Protocol *protocol = yl_dataSourceProtocol([self class]);
    Class class = yl_dynamicDelegateClass([self class], @"DataSource");
    return [self yl_dynamicDelegateWithClass:class forProtocol:protocol];
}
- (id)yl_dynamicDelegate
{
    Protocol *protocol = yl_delegateProtocol([self class]);
    Class class = yl_dynamicDelegateClass([self class], @"Delegate");
    return [self yl_dynamicDelegateWithClass:class forProtocol:protocol];
}
- (id)yl_dynamicDelegateForProtocol:(Protocol *)protocol
{
    Class class = [YLBlockDelegate class];
    NSString *protocolName = NSStringFromProtocol(protocol);
    if ([protocolName hasSuffix:@"Delegate"]) {
        class = yl_dynamicDelegateClass([self class], @"Delegate");
    } else if ([protocolName hasSuffix:@"DataSource"]) {
        class = yl_dynamicDelegateClass([self class], @"DataSource");
    }
    
    return [self yl_dynamicDelegateWithClass:class forProtocol:protocol];
}
- (id)yl_dynamicDelegateWithClass:(Class)cls forProtocol:(Protocol *)protocol
{
    /**
     * Storing the dynamic delegate as an associated object of the delegating
     * object not only allows us to later retrieve the delegate, but it also
     * creates a strong relationship to the delegate. Since delegates are weak
     * references on the part of the delegating object, a dynamic delegate
     * would be deallocated immediately after its declaring scope ends.
     * Therefore, this strong relationship is required to ensure that the
     * delegate's lifetime is at least as long as that of the delegating object.
     **/
    
    __block YLBlockDelegate *dynamicDelegate;
    
    dispatch_sync(yl_backgroundQueue(), ^{
        dynamicDelegate = objc_getAssociatedObject(self, (__bridge const void *)protocol);
        
        if (!dynamicDelegate)
        {
            dynamicDelegate = [[cls alloc] initWithProtocol:protocol];
            objc_setAssociatedObject(self, (__bridge const void *)protocol, dynamicDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    });
    
    return dynamicDelegate;
}

@end
