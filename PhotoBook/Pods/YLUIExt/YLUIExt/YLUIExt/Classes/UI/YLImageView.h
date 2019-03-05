#import <UIKit/UIKit.h>
#import <YLCore/YLMacro.h>
#import <YLCore/YLCallBackDefine.h>



typedef void (^YLImageViewRatioCallBack)(BOOL isSucc,CGFloat ratio);

@interface YLImageView : UIImageView

@property (nonatomic,assign)  CGFloat cornerRadius;
@property (nonatomic,assign)  CGFloat borderWidth;
@property (nonatomic,copy)  UIColor *borderColor;
@property (nonatomic,assign)  BOOL isRound;


@property (nonatomic,copy) NSString *imageUrl;
@property (nonatomic,copy) NSString *imageHolder;

-(void)getImageSize:(NSString*)url callBack:(YLImageViewRatioCallBack)callBack;

@end
