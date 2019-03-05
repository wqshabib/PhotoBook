#import "YLButton.h"
#import <objc/runtime.h>
#import <SDWebImage/UIButton+WebCache.h>

static char kTouchZoom;
static char kTouchSpring;
static char kAction;

@interface YLTouchBlockObserver : NSObject

@end

@implementation YLTouchBlockObserver

- (void)action:(YLButton *)button {
    if (button.touchZoom == YES) {
        return;
    }
    if (button.touchSpring == YES) {
        return;
    }
    if (button.onPress) {
        button.onPress(button);
    }
}
@end


@interface YLTouchAnimObserver : NSObject

@end

@implementation YLTouchAnimObserver

- (void)zoom:(YLButton *)button {
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        button.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL ok){
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            button.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished){
            if (button.onPress) {
                button.onPress(button);
            }
        }];
    }];
}

- (void)spring:(YLButton *)button {
    button.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:0.5
          initialSpringVelocity:1
                        options:UIViewAnimationOptionCurveEaseInOut animations:^{
                            button.transform = CGAffineTransformIdentity;
                        }
                     completion:^(BOOL finished){
                         if (button.onPress) {
                             button.onPress(button);
                         }
                     }];
}

@end

static YLTouchAnimObserver  *animateObserver;
static YLTouchBlockObserver *onPressObserver;

@implementation YLButton

-(void)setCornerRadius:(CGFloat)cornerRadius{
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = cornerRadius;
}

-(CGFloat)cornerRadius{
    return self.layer.cornerRadius;
}

-(void)setBorderColor:(UIColor *)borderColor{
    self.layer.borderColor = borderColor.CGColor;
}

-(CGFloat)borderWidth{
    return self.layer.borderWidth;
}

-(UIColor *)borderColor{
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

-(void)setBorderWidth:(CGFloat)borderWidth{
    self.layer.borderWidth = borderWidth;
}

-(void)setIsRound:(BOOL)isRound {
    if (isRound) {
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius  = self.bounds.size.height/2;
    }
    else {
        self.layer.masksToBounds = NO;
        self.layer.cornerRadius = 0;
    }
}

-(BOOL)isRound {
    return self.layer.cornerRadius == self.bounds.size.height/2;
}

+ (void)load {
    animateObserver = [[YLTouchAnimObserver alloc] init];
    onPressObserver = [[YLTouchBlockObserver alloc] init];
}

-(BOOL)touchZoom
{
    NSNumber *val = objc_getAssociatedObject(self, &kTouchZoom);
    return [val intValue];
}

-(void)setTouchZoom:(BOOL)touchZoom
{
    objc_setAssociatedObject(self,&kTouchZoom, @(touchZoom), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (touchZoom) {
        [self addTarget:animateObserver action:@selector(zoom:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(BOOL)touchSpring
{
    NSNumber *val = objc_getAssociatedObject(self, &kTouchSpring);
    return [val intValue];
}

-(void)setTouchSpring:(BOOL)touchSpring
{
    objc_setAssociatedObject(self,&kTouchSpring, @(touchSpring), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (touchSpring) {
        [self addTarget:animateObserver action:@selector(spring:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(YLButtonOnPress)onPress
{
    return objc_getAssociatedObject(self, &kAction);
}

-(void)setOnPress:(YLButtonOnPress)onPress
{
    objc_setAssociatedObject(self,&kAction, onPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (onPress) {
        [self addTarget:onPressObserver action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)setImageUrl:(NSString *)imageUrl {
    UIImage *placeHolder = [UIImage imageNamed:self.imageHolder];
    [self sd_setBackgroundImageWithURL:[NSURL URLWithString:imageUrl]
                    forState:UIControlStateNormal placeholderImage:placeHolder ? placeHolder : self.currentBackgroundImage];
}

-(void)setImageHolder:(NSString *)imageHolder {
    _imageHolder = imageHolder;
    [self setBackgroundImage:[UIImage imageNamed:imageHolder] forState:UIControlStateNormal];
}

@end
