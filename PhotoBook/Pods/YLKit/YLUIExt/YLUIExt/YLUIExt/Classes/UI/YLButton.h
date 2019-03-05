#import <UIKit/UIKit.h>
#import <YLCore/YLMacro.h>
#import <YLCore/YLCallBackDefine.h>

@class YLButton;

typedef void (^YLButtonOnPress)(YLButton *button);

IB_DESIGNABLE

@interface YLButton : UIButton

@property (nonatomic,assign) IBInspectable CGFloat cornerRadius;
@property (nonatomic,assign) IBInspectable CGFloat borderWidth;
@property (nonatomic,copy) IBInspectable UIColor *borderColor;
@property (nonatomic,assign) IBInspectable BOOL isRound;

@property (assign, nonatomic) IBInspectable BOOL touchZoom;
@property (assign, nonatomic) IBInspectable BOOL touchSpring;

@property (nonatomic,copy) YLButtonOnPress onPress;

@property (nonatomic,copy) NSString *imageUrl;
@property (nonatomic,copy) NSString *imageHolder;

@end
