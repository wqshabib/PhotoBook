#import <UIKit/UIKit.h>
#import <YLCore/YLMacro.h>
#import <YLCore/YLCallBackDefine.h>

@class YLButton;

typedef void (^YLButtonOnPress)(YLButton *button);

@interface YLButton : UIButton

@property (nonatomic,assign)  CGFloat cornerRadius;
@property (nonatomic,assign)  CGFloat borderWidth;
@property (nonatomic,copy)  UIColor *borderColor;
@property (nonatomic,assign)  BOOL isRound;

@property (assign, nonatomic)  BOOL touchZoom;
@property (assign, nonatomic)  BOOL touchSpring;

@property (nonatomic,copy) YLButtonOnPress onPress;

@property (nonatomic,copy) NSString *imageUrl;
@property (nonatomic,copy) NSString *imageHolder;

@end
