#import "YLTextField.h"
#import <objc/runtime.h>
#import "YLBlockHeader.h"

static char kMaxLength;
static char kResignReturn;
static char kPlaceColor;
static char kFontSize;

@interface MaxLengthObserver : NSObject

@end

@implementation MaxLengthObserver

- (void)textChange:(YLTextField *)textField {
    NSString *destText = textField.text;
    NSUInteger maxLength = textField.max;
    UITextRange *selectedRange = [textField markedTextRange];
    if (!selectedRange || !selectedRange.start) {
        if (destText.length > maxLength) {
            textField.text = [destText substringToIndex:maxLength];
        }
    }
}

@end

static MaxLengthObserver *observer;


@implementation YLTextField

@dynamic max;
@dynamic resignReturn;
@dynamic placeColor;
@dynamic placeFont;
@dynamic shouldBeginEditingBlock, didBeginEditingBlock, shouldEndEditingBlock, didEndEditingBlock, shouldChangeCharactersInRangeWithReplacementStringBlock, shouldClearBlock, shouldReturnBlock;

-(void)setIsNormal:(BOOL)isNormal {
    _isNormal = isNormal;
    if (!isNormal) {
        return;
    }
    self.resignReturn = YES;
}

-(void)setIsMoblie:(BOOL)isMoblie {
    _isMoblie = isMoblie;
    if (!isMoblie) {
        return;
    }
    self.max = 11;
    self.keyboardType = UIKeyboardTypeNumberPad;
    self.resignReturn = YES;
}

-(void)setIsPayWord:(BOOL)isPayWord {
    _isPayWord = isPayWord;
    if (!isPayWord) {
        return;
    }
    self.max = 6;
    self.secureTextEntry = YES;
    self.keyboardType = UIKeyboardTypeNumberPad;
    self.resignReturn = YES;
}

-(void)setIsVerificationCode:(BOOL)isVerificationCode {
    _isVerificationCode = isVerificationCode;
    if (!isVerificationCode) {
        return;
    }
    self.max = 6;
    self.keyboardType = UIKeyboardTypeNumberPad;
    self.resignReturn = YES;
    
}

-(void)setIsPrice:(BOOL)isPrice {
    _isPrice = isPrice;
    if (!isPrice) {
        return;
    }
    self.keyboardType = UIKeyboardTypeDecimalPad;
    self.resignReturn = YES;
}

-(void)setIsBuyNumber:(BOOL)isBuyNumber {
    _isBuyNumber = isBuyNumber;
    if (!isBuyNumber) {
        return;
    }
    self.max = 3;
    self.keyboardType = UIKeyboardTypeNumberPad;
    self.resignReturn = YES;
}

-(BOOL)isAvailable {
    if (self.isNormal) {
        if (self.text.length > 0) {
            return YES;
        }
        return NO;
    }
    if (self.isMoblie) {
        if (self.text.length == 11) {
            return YES;
        }
        return NO;
    }
    if (self.isVerificationCode) {
        if (self.text.length == 6) {
            return YES;
        }
        return NO;
    }
    if (self.isPayWord) {
        if (self.text.length == 6) {
            return YES;
        }
        return NO;
    }
    return NO;
}

+ (void)load {
    observer = [[MaxLengthObserver alloc] init];
    [self yl_registerDynamicDelegate];
    [self yl_linkDelegateMethods: @{
                                    @"shouldBeginEditingBlock": @"textFieldShouldBeginEditing:",
                                    @"didBeginEditingBlock": @"textFieldDidBeginEditing:",
                                    @"shouldEndEditingBlock": @"textFieldShouldEndEditing:",
                                    @"didEndEditingBlock" : @"textFieldDidEndEditing:",
                                    @"shouldChangeCharactersInRangeWithReplacementStringBlock" : @"textField:shouldChangeCharactersInRange:replacementString:",
                                    @"shouldClearBlock" : @"textFieldShouldClear:",
                                    @"shouldReturnBlock" : @"textFieldShouldReturn:",
                                    }];
}

- (void)setMax:(NSUInteger)max {
    objc_setAssociatedObject(self, &kMaxLength, @(max), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (max) {
        [self addTarget:observer
                 action:@selector(textChange:)
       forControlEvents:UIControlEventEditingChanged];
    }
}

-(BOOL)resignReturn{
    NSNumber *val = objc_getAssociatedObject(self, &kResignReturn);
    return [val intValue];
}

-(void)setResignReturn:(BOOL)resignReturn{
    objc_setAssociatedObject(self,&kResignReturn, @(resignReturn), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (resignReturn) {
        self.shouldReturnBlock = ^BOOL(YLTextField *tf){
            [tf resignFirstResponder];
            return YES;
        };
    }
}

-(void)setPlaceColor:(UIColor *)placeColor
{
    objc_setAssociatedObject(self,&kPlaceColor,placeColor,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (placeColor) {
        [self setValue:placeColor forKeyPath:@"_placeholderLabel.textColor"];
    }
}

-(UIColor*)placeColor
{
    return objc_getAssociatedObject(self, &kPlaceColor);
}

-(void)setPlaceFont:(NSUInteger)placeFont
{
    objc_setAssociatedObject(self, &kFontSize, @(placeFont), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (placeFont) {
        [self setValue:[UIFont boldSystemFontOfSize:placeFont] forKeyPath:@"_placeholderLabel.font"];
    }
}

-(NSUInteger)placeFont
{
    NSNumber *number = objc_getAssociatedObject(self, &kFontSize);
    return [number integerValue];
}



-(NSUInteger)max {
    NSNumber *number = objc_getAssociatedObject(self, &kMaxLength);
    return [number integerValue];
}

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

@end

@interface YLBlockYLTextFieldDelegate : YLBlockDelegate

@end

@implementation YLBlockYLTextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(YLTextField *)textField
{
    BOOL ret = YES;
    id realDelegate = self.realDelegate;
    if (realDelegate && [realDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)])
        ret = [realDelegate textFieldShouldBeginEditing:textField];
    BOOL (^block)(YLTextField *) = [self blockImplementationForMethod:_cmd];
    if (block)
        ret &= block(textField);
    return ret;
}

- (void)textFieldDidBeginEditing:(YLTextField *)textField
{
    id realDelegate = self.realDelegate;
    if (realDelegate && [realDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)])
        [realDelegate textFieldDidBeginEditing:textField];
    void (^block)(YLTextField *) = [self blockImplementationForMethod:_cmd];
    if (block)
        block(textField);
}

- (BOOL)textFieldShouldEndEditing:(YLTextField *)textField
{
    BOOL ret = YES;
    id realDelegate = self.realDelegate;
    if (realDelegate && [realDelegate respondsToSelector:@selector(textFieldShouldEndEditing:)])
        ret = [realDelegate textFieldShouldEndEditing:textField];
    BOOL (^block)(YLTextField *) = [self blockImplementationForMethod:_cmd];
    if (block)
        ret &= block(textField);
    return ret;
}

- (void)textFieldDidEndEditing:(YLTextField *)textField
{
    id realDelegate = self.realDelegate;
    if (realDelegate && [realDelegate respondsToSelector:@selector(textFieldDidEndEditing:)])
        [realDelegate textFieldDidEndEditing:textField];
    void (^block)(YLTextField *) = [self blockImplementationForMethod:_cmd];
    if (block)
        block(textField);
}

- (BOOL)textField:(YLTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL ret = YES;
    id realDelegate = self.realDelegate;
    if (realDelegate && [realDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)])
        ret = [realDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
    BOOL (^block)(YLTextField *, NSRange, NSString *) = [self blockImplementationForMethod:_cmd];
    if (block)
        ret &= block(textField, range, string);
    return ret;
}

- (BOOL)textFieldShouldClear:(YLTextField *)textField
{
    BOOL ret = YES;
    id realDelegate = self.realDelegate;
    if (realDelegate && [realDelegate respondsToSelector:@selector(textFieldShouldClear:)])
        ret = [realDelegate textFieldShouldClear:textField];
    BOOL (^block)(YLTextField *) = [self blockImplementationForMethod:_cmd];
    if (block)
        ret &= block(textField);
    return ret;
}

- (BOOL)textFieldShouldReturn:(YLTextField *)textField
{
    BOOL ret = YES;
    id realDelegate = self.realDelegate;
    if (realDelegate && [realDelegate respondsToSelector:@selector(textFieldShouldReturn:)])
        ret = [realDelegate textFieldShouldReturn:textField];
    BOOL (^block)(YLTextField *) = [self blockImplementationForMethod:_cmd];
    if (block)
        ret &= block(textField);
    return ret;
}



@end
