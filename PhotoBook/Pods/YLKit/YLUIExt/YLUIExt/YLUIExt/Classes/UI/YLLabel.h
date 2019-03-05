#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface YLLabel : UILabel

@property (nonatomic,assign) IBInspectable CGFloat cornerRadius;
@property (nonatomic,assign) IBInspectable CGFloat borderWidth;
@property (nonatomic,copy) IBInspectable UIColor *borderColor;
@property (nonatomic,assign) IBInspectable BOOL isRound;

@end
