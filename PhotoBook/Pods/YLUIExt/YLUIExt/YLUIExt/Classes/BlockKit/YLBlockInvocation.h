#import <Foundation/Foundation.h>

extern NSString *const A2IncompatibleMethodSignatureKey;


@interface YLBlockInvocation : NSObject


+ (NSMethodSignature *)methodSignatureForBlock:(id)block;


- (instancetype)initWithBlock:(id)block;


- (instancetype)initWithBlock:(id)block methodSignature:(NSMethodSignature *)methodSignature;


@property (nonatomic, strong, readonly) NSMethodSignature *methodSignature;


@property (nonatomic, copy, readonly) id block;


- (BOOL)invokeWithInvocation:(NSInvocation *)inv returnValue:(out NSValue **)returnValue;


- (void)invokeWithInvocation:(NSInvocation *)inv;

@end
