#import <UIKit/UIKit.h>
#import <YLCore/YLMacro.h>
#import <YLCore/YLCallBackDefine.h>

IB_DESIGNABLE

typedef void (^YLImageViewRatioCallBack)(BOOL isSucc,CGFloat ratio);

@interface YLImageView : UIImageView

@property (nonatomic,assign) IBInspectable CGFloat cornerRadius;
@property (nonatomic,assign) IBInspectable CGFloat borderWidth;
@property (nonatomic,copy) IBInspectable UIColor *borderColor;
@property (nonatomic,assign) IBInspectable BOOL isRound;


@property (nonatomic,copy) NSString *imageUrl;
@property (nonatomic,copy) NSString *imageHolder;

-(void)getImageSize:(NSString*)url callBack:(YLImageViewRatioCallBack)callBack;

@end
