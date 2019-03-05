#import <Foundation/Foundation.h>
#import "NSObject+YLBlockDelegate.h"
#import "NSObject+YLDynamicDelegate.h"

@interface YLBlockDelegate : NSProxy

- (id)initWithProtocol:(Protocol *)protocol;


@property (nonatomic, readonly) Protocol *protocol;


@property (nonatomic, strong, readonly) NSMutableDictionary *handlers;


@property (nonatomic, weak, readonly) id realDelegate;


- (id)blockImplementationForMethod:(SEL)selector;

- (void)implementMethod:(SEL)selector withBlock:(id)block;

- (void)removeBlockImplementationForMethod:(SEL)selector;

- (id)blockImplementationForClassMethod:(SEL)selector;


- (void)implementClassMethod:(SEL)selector withBlock:(id)block;


- (void)removeBlockImplementationForClassMethod:(SEL)selector;
@end
