
#import <objc/message.h>
#import "NSObject+YLBlockDelegate.h"
#import "NSObject+YLDynamicDelegate.h"

#pragma mark - Declarations and macros

extern Protocol *yl_dataSourceProtocol(Class cls);
extern Protocol *yl_delegateProtocol(Class cls);

#pragma mark - Functions

static BOOL yl_object_isKindOfClass(id obj, Class testClass)
{
    BOOL isKindOfClass = NO;
    Class cls = object_getClass(obj);
    while (cls && !isKindOfClass) {
        isKindOfClass = (cls == testClass);
        cls = class_getSuperclass(cls);
    }
    
    return isKindOfClass;
}

static Protocol *yl_protocolForDelegatingObject(id obj, Protocol *protocol)
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

static inline BOOL isValidIMP(IMP impl) {
#if defined(__arm64__)
    if (impl == NULL || impl == _objc_msgForward) return NO;
#else
    if (impl == NULL || impl == _objc_msgForward || impl == (IMP)_objc_msgForward_stret) return NO;
#endif
    return YES;
}

static BOOL addMethodWithIMP(Class cls, SEL oldSel, SEL newSel, IMP newIMP, const char *types, BOOL aggressive) {
    if (!class_addMethod(cls, oldSel, newIMP, types)) {
        return NO;
    }
    
    // We just ended up implementing a method that doesn't exist
    // (-[NSURLConnection setDelegate:]) or overrode a superclass
    // version (-[UIImagePickerController setDelegate:]).
    IMP parentIMP = NULL;
    Class superclass = class_getSuperclass(cls);
    while (superclass && !isValidIMP(parentIMP)) {
        parentIMP = class_getMethodImplementation(superclass, oldSel);
        if (isValidIMP(parentIMP)) {
            break;
        } else {
            parentIMP = NULL;
        }
        
        superclass = class_getSuperclass(superclass);
    }
    
    if (parentIMP) {
        if (aggressive) {
            return class_addMethod(cls, newSel, parentIMP, types);
        }
        
        class_replaceMethod(cls, newSel, newIMP, types);
        class_replaceMethod(cls, oldSel, parentIMP, types);
    }
    
    return YES;
}

static BOOL swizzleWithIMP(Class cls, SEL oldSel, SEL newSel, IMP newIMP, const char *types, BOOL aggressive) {
    Method origMethod = class_getInstanceMethod(cls, oldSel);
    
    if (addMethodWithIMP(cls, oldSel, newSel, newIMP, types, aggressive)) {
        return YES;
    }
    
    // common case, actual swap
    BOOL ret = class_addMethod(cls, newSel, newIMP, types);
    Method newMethod = class_getInstanceMethod(cls, newSel);
    method_exchangeImplementations(origMethod, newMethod);
    return ret;
}

static SEL selectorWithPattern(const char *prefix, const char *key, const char *suffix) {
    size_t prefixLength = prefix ? strlen(prefix) : 0;
    size_t suffixLength = suffix ? strlen(suffix) : 0;
    
    char initial = key[0];
    if (prefixLength) initial = (char)toupper(initial);
    size_t initialLength = 1;
    
    const char *rest = key + initialLength;
    size_t restLength = strlen(rest);
    
    char selector[prefixLength + initialLength + restLength + suffixLength + 1];
    memcpy(selector, prefix, prefixLength);
    selector[prefixLength] = initial;
    memcpy(selector + prefixLength + initialLength, rest, restLength);
    memcpy(selector + prefixLength + initialLength + restLength, suffix, suffixLength);
    selector[prefixLength + initialLength + restLength + suffixLength] = '\0';
    
    return sel_registerName(selector);
}

static SEL getterForProperty(objc_property_t property, const char *name)
{
    if (property) {
        char *getterName = property_copyAttributeValue(property, "G");
        if (getterName) {
            SEL getter = sel_getUid(getterName);
            free(getterName);
            if (getter) return getter;
        }
    }
    
    const char *propertyName = property ? property_getName(property) : name;
    return sel_registerName(propertyName);
}

static SEL setterForProperty(objc_property_t property, const char *name)
{
    if (property) {
        char *setterName = property_copyAttributeValue(property, "S");
        if (setterName) {
            SEL setter = sel_getUid(setterName);
            free(setterName);
            if (setter) return setter;
        }
    }
    
    const char *propertyName = property ? property_getName(property) : name;
    return selectorWithPattern("set", propertyName, ":");
}

static inline SEL prefixedSelector(SEL original) {
    return selectorWithPattern("yl_", sel_getName(original), NULL);
}

#pragma mark -

typedef struct {
    SEL setter;
    SEL yl_setter;
    SEL getter;
} A2BlockDelegateInfo;

static NSUInteger A2BlockDelegateInfoSize(const void *__unused item) {
    return sizeof(A2BlockDelegateInfo);
}

static NSString *A2BlockDelegateInfoDescribe(const void *__unused item) {
    if (!item) { return nil; }
    const A2BlockDelegateInfo *info = item;
    return [NSString stringWithFormat:@"(setter: %s, getter: %s)", sel_getName(info->setter), sel_getName(info->getter)];
}

static inline YLBlockDelegate *getDynamicDelegate(NSObject *delegatingObject, Protocol *protocol, const A2BlockDelegateInfo *info, BOOL ensuring) {
    YLBlockDelegate *dynamicDelegate = [delegatingObject yl_dynamicDelegateForProtocol:yl_protocolForDelegatingObject(delegatingObject, protocol)];
    
    if (!info || !info->setter || !info->getter) {
        return dynamicDelegate;
    }
    
    if (!info->yl_setter && !info->setter) { return dynamicDelegate; }
    
    id (*getterDispatch)(id, SEL) = (id (*)(id, SEL)) objc_msgSend;
    id originalDelegate = getterDispatch(delegatingObject, info->getter);
    
    if (yl_object_isKindOfClass(originalDelegate, YLBlockDelegate.class)) { return dynamicDelegate; }
    
    void (*setterDispatch)(id, SEL, id) = (void (*)(id, SEL, id)) objc_msgSend;
    setterDispatch(delegatingObject, info->yl_setter ?: info->setter, dynamicDelegate);
    
    return dynamicDelegate;
}

typedef YLBlockDelegate *(^A2GetDynamicDelegateBlock)(NSObject *, BOOL);

@interface YLBlockDelegate ()

@property (nonatomic, weak, readwrite) id realDelegate;

@end

#pragma mark -

@implementation NSObject (YLBlockDelegate)

#pragma mark Helpers

+ (NSMapTable *)yl_delegateInfoByProtocol:(BOOL)createIfNeeded
{
    NSMapTable *delegateInfo = objc_getAssociatedObject(self, _cmd);
    if (delegateInfo || !createIfNeeded) { return delegateInfo; }
    
    NSPointerFunctions *protocols = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsOpaqueMemory|NSPointerFunctionsObjectPointerPersonality];
    NSPointerFunctions *infoStruct = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsMallocMemory|NSPointerFunctionsStructPersonality|NSPointerFunctionsCopyIn];
    infoStruct.sizeFunction = A2BlockDelegateInfoSize;
    infoStruct.descriptionFunction = A2BlockDelegateInfoDescribe;
    
    delegateInfo = [[NSMapTable alloc] initWithKeyPointerFunctions:protocols valuePointerFunctions:infoStruct capacity:0];
    objc_setAssociatedObject(self, _cmd, delegateInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return delegateInfo;
}

+ (const A2BlockDelegateInfo *)yl_delegateInfoForProtocol:(Protocol *)protocol
{
    A2BlockDelegateInfo *infoAsPtr = NULL;
    Class cls = self;
    while ((infoAsPtr == NULL || infoAsPtr->getter == NULL) && cls != nil && cls != NSObject.class) {
        NSMapTable *map = [cls yl_delegateInfoByProtocol:NO];
        infoAsPtr = (__bridge void *)[map objectForKey:protocol];
        cls = [cls superclass];
    }
    NSCAssert(infoAsPtr != NULL, @"Class %@ not assigned dynamic delegate for protocol %@", NSStringFromClass(self), NSStringFromProtocol(protocol));
    return infoAsPtr;
}

#pragma mark Linking block properties

+ (void)yl_linkDataSourceMethods:(NSDictionary *)dictionary
{
    [self yl_linkProtocol:yl_dataSourceProtocol(self) methods:dictionary];
}

+ (void)yl_linkDelegateMethods:(NSDictionary *)dictionary
{
    [self yl_linkProtocol:yl_delegateProtocol(self) methods:dictionary];
}

+ (void)yl_linkProtocol:(Protocol *)protocol methods:(NSDictionary *)dictionary
{
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *selectorName, BOOL *stop) {
        const char *name = propertyName.UTF8String;
        objc_property_t property = class_getProperty(self, name);
        NSCAssert(property, @"Property \"%@\" does not exist on class %s", propertyName, class_getName(self));
        
        char *dynamic = property_copyAttributeValue(property, "D");
        NSCAssert2(dynamic, @"Property \"%@\" on class %s must be backed with \"@dynamic\"", propertyName, class_getName(self));
        free(dynamic);
        
        char *copy = property_copyAttributeValue(property, "C");
        NSCAssert2(copy, @"Property \"%@\" on class %s must be defined with the \"copy\" attribute", propertyName, class_getName(self));
        free(copy);
        
        SEL selector = NSSelectorFromString(selectorName);
        SEL getter = getterForProperty(property, name);
        SEL setter = setterForProperty(property, name);
        
        if (class_respondsToSelector(self, setter) || class_respondsToSelector(self, getter)) { return; }
        
        const A2BlockDelegateInfo *info = [self yl_delegateInfoForProtocol:protocol];
        
        IMP getterImplementation = imp_implementationWithBlock(^(NSObject *delegatingObject) {
            YLBlockDelegate *delegate = getDynamicDelegate(delegatingObject, protocol, info, NO);
            return [delegate blockImplementationForMethod:selector];
        });
        
        if (!class_addMethod(self, getter, getterImplementation, "@@:")) {
            NSCAssert(NO, @"Could not implement getter for \"%@\" property.", propertyName);
        }
        
        IMP setterImplementation = imp_implementationWithBlock(^(NSObject *delegatingObject, id block) {
            YLBlockDelegate *delegate = getDynamicDelegate(delegatingObject, protocol, info, YES);
            [delegate implementMethod:selector withBlock:block];
        });
        
        if (!class_addMethod(self, setter, setterImplementation, "v@:@")) {
            NSCAssert(NO, @"Could not implement setter for \"%@\" property.", propertyName);
        }
    }];
}

#pragma mark Dynamic Delegate Replacement

+ (void)yl_registerDynamicDataSource
{
    [self yl_registerDynamicDelegateNamed:@"dataSource" forProtocol:yl_dataSourceProtocol(self)];
}
+ (void)yl_registerDynamicDelegate
{
    [self yl_registerDynamicDelegateNamed:@"delegate" forProtocol:yl_delegateProtocol(self)];
}

+ (void)yl_registerDynamicDataSourceNamed:(NSString *)dataSourceName
{
    [self yl_registerDynamicDelegateNamed:dataSourceName forProtocol:yl_dataSourceProtocol(self)];
}
+ (void)yl_registerDynamicDelegateNamed:(NSString *)delegateName
{
    [self yl_registerDynamicDelegateNamed:delegateName forProtocol:yl_delegateProtocol(self)];
}

+ (void)yl_registerDynamicDelegateNamed:(NSString *)delegateName forProtocol:(Protocol *)protocol
{
    NSMapTable *propertyMap = [self yl_delegateInfoByProtocol:YES];
    A2BlockDelegateInfo *infoAsPtr = (__bridge void *)[propertyMap objectForKey:protocol];
    if (infoAsPtr != NULL) { return; }
    
    const char *name = delegateName.UTF8String;
    objc_property_t property = class_getProperty(self, name);
    SEL setter = setterForProperty(property, name);
    SEL yl_setter = prefixedSelector(setter);
    SEL getter = getterForProperty(property, name);
    
    A2BlockDelegateInfo info = {
        setter, yl_setter, getter
    };
    
    [propertyMap setObject:(__bridge id)&info forKey:protocol];
    infoAsPtr = (__bridge void *)[propertyMap objectForKey:protocol];
    
    IMP setterImplementation = imp_implementationWithBlock(^(NSObject *delegatingObject, id delegate) {
        YLBlockDelegate *dynamicDelegate = getDynamicDelegate(delegatingObject, protocol, infoAsPtr, YES);
        if ([delegate isEqual:dynamicDelegate]) {
            delegate = nil;
        }
        dynamicDelegate.realDelegate = delegate;
    });
    
    if (!swizzleWithIMP(self, setter, yl_setter, setterImplementation, "v@:@", YES)) {
        bzero(infoAsPtr, sizeof(A2BlockDelegateInfo));
        return;
    }
    
    if (![self instancesRespondToSelector:getter]) {
        IMP getterImplementation = imp_implementationWithBlock(^(NSObject *delegatingObject) {
            return [delegatingObject yl_dynamicDelegateForProtocol:yl_protocolForDelegatingObject(delegatingObject, protocol)];
        });
        
        addMethodWithIMP(self, getter, NULL, getterImplementation, "@@:", NO);
    }
}

- (id)yl_ensuredDynamicDelegate
{
    Protocol *protocol = yl_delegateProtocol(self.class);
    return [self yl_ensuredDynamicDelegateForProtocol:protocol];
}

- (id)yl_ensuredDynamicDelegateForProtocol:(Protocol *)protocol
{
    const A2BlockDelegateInfo *info = [self.class yl_delegateInfoForProtocol:protocol];
    return getDynamicDelegate(self, protocol, info, YES);
}

@end

