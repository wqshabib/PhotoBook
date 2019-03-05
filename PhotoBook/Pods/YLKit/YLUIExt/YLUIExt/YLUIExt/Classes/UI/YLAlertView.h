#import <UIKit/UIKit.h>
#import <YLCore/YLMacro.h>
#import <YLCore/YLCallBackDefine.h>

@interface YLAlertView : NSObject

@property (nonatomic,copy) CallBack onSure;
@property (nonatomic,copy) CallBack onCancel;

+(void)showTitle:(NSString*)title
         message:(NSString*)message
       sureTitle:(NSString*)sureTitle
     cancelTitle:(NSString*)cancelTitle
            inVC:(UIViewController*)inVC
          onSure:(CallBack)onSure
        onCancel:(CallBack)onCancel;

+(void)showMessage:(NSString*)message
              inVC:(UIViewController*)inVC
            onSure:(CallBack)onSure;

+(void)showMessage:(NSString*)message
              inVC:(UIViewController*)inVC
            onSure:(CallBack)onSure
          onCancel:(CallBack)onCancel;

+(void)showSingleButtonWithMessage:(NSString*)message inVC:(UIViewController*)inVC onSure:(CallBack)onSure;


@end

