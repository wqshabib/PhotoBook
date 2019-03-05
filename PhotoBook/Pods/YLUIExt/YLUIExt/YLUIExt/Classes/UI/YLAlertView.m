#import "YLAlertView.h"

@implementation YLAlertView

+(void)showTitle:(NSString*)title
         message:(NSString*)message
       sureTitle:(NSString*)sureTitle
     cancelTitle:(NSString*)cancelTitle
            inVC:(UIViewController*)inVC
          onSure:(CallBack)onSure
        onCancel:(CallBack)onCancel {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:sureTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (onSure) {
            onSure();
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {        if (onCancel) {
            onCancel();
        }
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [inVC presentViewController:alertController animated:YES completion:nil];
}

+(void)showMessage:(NSString*)message
              inVC:(UIViewController*)inVC
            onSure:(CallBack)onSure

{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (onSure) {
            onSure();
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { 
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [inVC presentViewController:alertController animated:YES completion:nil];
}

+(void)showSingleButtonWithMessage:(NSString*)message inVC:(UIViewController*)inVC onSure:(CallBack)onSure {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (onSure) {
            onSure();
        }
    }];
    [alertController addAction:okAction];
    [inVC presentViewController:alertController animated:YES completion:nil];
}


+(void)showMessage:(NSString*)message
              inVC:(UIViewController*)inVC
            onSure:(CallBack)onSure
          onCancel:(CallBack)onCancel
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (onSure) {
            onSure();
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (onCancel) {
            onCancel();
        }
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [inVC presentViewController:alertController animated:YES completion:nil];
}
@end
