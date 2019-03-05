//
//  YLBlockDelegate.m
//  EmberKit
//
//  Created by Ember on 2017/8/11.
//  Copyright © 2017年 Ember. All rights reserved.
//

#import "YLBlockDelegate.h"
#import <objc/message.h>
#import "YLBlockInvocation.h"
#import "YLBlockDelegate.h"

Protocol *yl_dataSourceProtocol(Class cls);
Protocol *yl_delegateProtocol(Class cls);
Protocol *yl_protocolForDelegatingObject(id obj, Protocol *protocol);

static BOOL selectorsEqual(const void *item1, const void *item2, NSUInteger(*__unused size)(const void __unused *item))
{
    return sel_isEqual((SEL)item1, (SEL)item2);
}

static NSString *selectorDescribe(const void *item1)
{
    return NSStringFromSelector((SEL)item1);
}

@interface NSMapTable (BKAdditions)

+ (instancetype)yl_selectorsToStrongObjectsMapTable;
- (id)yl_objectForSelector:(SEL)aSEL;
- (void)yl_removeObjectForSelector:(SEL)aSEL;
- (void)yl_setObject:(id)anObject forSelector:(SEL)aSEL;

@end

@implementation NSMapTable (BKAdditions)

+ (instancetype)yl_selectorsToStrongObjectsMapTable
{
    NSPointerFunctions *selectors = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsOpaqueMemory|NSPointerFunctionsOpaquePersonality];
    selectors.isEqualFunction = selectorsEqual;
    selectors.descriptionFunction = selectorDescribe;
    
    NSPointerFunctions *strongObjects = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality];
    
    return [[NSMapTable alloc] initWithKeyPointerFunctions:selectors valuePointerFunctions:strongObjects capacity:1];
}

- (id)yl_objectForSelector:(SEL)aSEL
{
    void *selAsPtr = aSEL;
    return [self objectForKey:(__bridge id)selAsPtr];
}

- (void)yl_removeObjectForSelector:(SEL)aSEL
{
    void *selAsPtr = aSEL;
    [self removeObjectForKey:(__bridge id)selAsPtr];
}

- (void)yl_setObject:(id)anObject forSelector:(SEL)aSEL
{
    void *selAsPtr = aSEL;
    [self setObject:anObject forKey:(__bridge id)selAsPtr];
}


@end

@interface YLDynamicClassDelegate : YLBlockDelegate

@property (nonatomic) Class proxiedClass;

@end

#pragma mark -

@interface YLBlockDelegate ()

@property (nonatomic) YLDynamicClassDelegate *classProxy;
@property (nonatomic, readonly) NSMapTable *invocationsBySelectors;
@property (nonatomic, weak, readwrite) id realDelegate;

- (BOOL) isClassProxy;

@end

@implementation YLBlockDelegate

- (YLDynamicClassDelegate *)classProxy
{
    if (!_classProxy)
    {
        _classProxy = [[YLDynamicClassDelegate alloc] initWithProtocol:self.protocol];
        _classProxy.proxiedClass = object_getClass(self);
    }
    
    return _classProxy;
}

- (BOOL)isClassProxy
{
    return NO;
}

- (Class)class
{
    Class myClass = object_getClass(self);
    if (myClass == [YLBlockDelegate class] || [myClass superclass] == [YLBlockDelegate class])
        return (Class)self.classProxy;
    return [super class];
}

- (id)initWithProtocol:(Protocol *)protocol
{
    _protocol = protocol;
    _handlers = [NSMutableDictionary dictionary];
    _invocationsBySelectors = [NSMapTable yl_selectorsToStrongObjectsMapTable];
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    YLBlockInvocation *invocation = nil;
    if ((invocation = [self.invocationsBySelectors yl_objectForSelector:aSelector]))
        return invocation.methodSignature;
    else if ([self.realDelegate methodSignatureForSelector:aSelector])
        return [self.realDelegate methodSignatureForSelector:aSelector];
    else if (class_respondsToSelector(object_getClass(self), aSelector))
        return [object_getClass(self) methodSignatureForSelector:aSelector];
    return [[NSObject class] methodSignatureForSelector:aSelector];
}

+ (NSString *)description
{
    return @"A2DynamicDelegate";
}
- (NSString *)description
{
    return [NSString stringWithFormat:@"<A2DynamicDelegate:%p; protocol = %@>", (__bridge void *)self, NSStringFromProtocol(self.protocol)];
}

- (void)forwardInvocation:(NSInvocation *)outerInv
{
    SEL selector = outerInv.selector;
    YLBlockInvocation *innerInv = nil;
    if ((innerInv = [self.invocationsBySelectors yl_objectForSelector:selector])) {
        [innerInv invokeWithInvocation:outerInv];
    } else if ([self.realDelegate respondsToSelector:selector]) {
        [outerInv invokeWithTarget:self.realDelegate];
    }
}

#pragma mark -

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return protocol_isEqual(aProtocol, self.protocol) || [super conformsToProtocol:aProtocol];
}
- (BOOL)respondsToSelector:(SEL)selector
{
    return [self.invocationsBySelectors yl_objectForSelector:selector] || class_respondsToSelector(object_getClass(self), selector) || [self.realDelegate respondsToSelector:selector];
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    [NSException raise:NSInvalidArgumentException format:@"-[%s %@]: unrecognized selector sent to instance %p", object_getClassName(self), NSStringFromSelector(aSelector), (__bridge void *)self];
}

#pragma mark - Block Instance Method Implementations

- (id)blockImplementationForMethod:(SEL)selector
{
    YLBlockInvocation *invocation = nil;
    if ((invocation = [self.invocationsBySelectors yl_objectForSelector:selector]))
        return invocation.block;
    return NULL;
}

- (void)implementMethod:(SEL)selector withBlock:(id)block
{
    NSCAssert(selector, @"Attempt to implement or remove NULL selector");
    BOOL isClassMethod = self.isClassProxy;
    
    if (!block) {
        [self.invocationsBySelectors yl_removeObjectForSelector:selector];
        return;
    }
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(self.protocol, selector, YES, !isClassMethod);
    if (!methodDescription.name) methodDescription = protocol_getMethodDescription(self.protocol, selector, NO, !isClassMethod);
    
    YLBlockInvocation *inv = nil;
    if (methodDescription.name) {
        NSMethodSignature *protoSig = [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
        inv = [[YLBlockInvocation alloc] initWithBlock:block methodSignature:protoSig];
    } else {
        inv = [[YLBlockInvocation alloc] initWithBlock:block];
    }
    
    [self.invocationsBySelectors yl_setObject:inv forSelector:selector];
}
- (void)removeBlockImplementationForMethod:(SEL)selector __unused
{
    [self implementMethod:selector withBlock:nil];
}

#pragma mark - Block Class Method Implementations

- (id)blockImplementationForClassMethod:(SEL)selector
{
    return [self.classProxy blockImplementationForMethod:selector];
}

- (void)implementClassMethod:(SEL)selector withBlock:(id)block
{
    [self.classProxy implementMethod:selector withBlock:block];
}
- (void)removeBlockImplementationForClassMethod:(SEL)selector __unused
{
    [self.classProxy implementMethod:selector withBlock:nil];
}

@end

#pragma mark -

@implementation YLDynamicClassDelegate

- (BOOL)isClassProxy
{
    return YES;
}
- (BOOL)isEqual:(id)object
{
    return [super isEqual:object] || [_proxiedClass isEqual:object];
}
- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.invocationsBySelectors yl_objectForSelector:aSelector] || [_proxiedClass respondsToSelector:aSelector];
}

- (Class)class
{
    return self.proxiedClass;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    YLBlockInvocation *invocation = nil;
    if ((invocation = [self.invocationsBySelectors yl_objectForSelector:aSelector]))
        return invocation.methodSignature;
    else if ([_proxiedClass methodSignatureForSelector:aSelector])
        return [_proxiedClass methodSignatureForSelector:aSelector];
    return [[NSObject class] methodSignatureForSelector:aSelector];
}

- (NSString *)description
{
    return [_proxiedClass description];
}

- (NSUInteger)hash
{
    return [_proxiedClass hash];
}

- (void)forwardInvocation:(NSInvocation *)outerInv
{
    SEL selector = outerInv.selector;
    YLBlockInvocation *innerInv = nil;
    if ((innerInv = [self.invocationsBySelectors yl_objectForSelector:selector])) {
        [innerInv invokeWithInvocation:outerInv];
    } else {
        [outerInv invokeWithTarget:_proxiedClass];
    }
}

#pragma mark - Unavailable Methods

- (id)blockImplementationForClassMethod:(SEL)selector
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)implementClassMethod:(SEL)selector withBlock:(id)block
{
    [self doesNotRecognizeSelector:_cmd];
}
- (void)removeBlockImplementationForClassMethod:(SEL)selector
{
    [self doesNotRecognizeSelector:_cmd];
}

@end

#pragma mark - Helper functions

static Protocol *yl_classProtocol(Class _cls, NSString *suffix, NSString *description)
{
    Class cls = _cls;
    while (cls) {
        NSString *className = NSStringFromClass(cls);
        NSString *protocolName = [className stringByAppendingString:suffix];
        Protocol *protocol = objc_getProtocol(protocolName.UTF8String);
        if (protocol) return protocol;
        
        cls = class_getSuperclass(cls);
    }
    
    NSCAssert(NO, @"Specify protocol explicitly: could not determine %@ protocol for class %@ (tried <%@>)", description, NSStringFromClass(_cls), [NSStringFromClass(_cls) stringByAppendingString:suffix]);
    return nil;
}

Protocol *yl_dataSourceProtocol(Class cls)
{
    return yl_classProtocol(cls, @"DataSource", @"data source");
}
Protocol *yl_delegateProtocol(Class cls)
{
    return yl_classProtocol(cls, @"Delegate", @"delegate");
}
Protocol *yl_protocolForDelegatingObject(id obj, Protocol *protocol)
{
    NSString *protocolName = NSStringFromProtocol(protocol);
    if ([protocolName hasSuffix:@"Delegate"]) {
        Protocol *p = yl_delegateProtocol([obj class]);
        if (p) return p;
    } else if ([protocolName hasSuffix:@"DataSource"]) {
        Protocol *p = yl_dataSourceProtocol([obj class]);
        if (p) return p;
    }
    
    return protocol;
}

