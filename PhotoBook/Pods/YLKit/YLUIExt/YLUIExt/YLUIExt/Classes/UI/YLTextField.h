#import <UIKit/UIKit.h>
#import <YLCore/YLMacro.h>
#import <YLCore/YLCallBackDefine.h>

IB_DESIGNABLE

@interface YLTextField : UITextField

@property (nonatomic,assign) IBInspectable CGFloat cornerRadius;
@property (nonatomic,assign) IBInspectable CGFloat borderWidth;
@property (nonatomic,copy) IBInspectable UIColor *borderColor;
@property (nonatomic,assign) IBInspectable BOOL isRound;

@property (nonatomic,assign) IBInspectable NSUInteger placeFont;
@property (nonatomic,copy) IBInspectable UIColor *placeColor;

@property (assign, nonatomic) IBInspectable NSUInteger max;
@property (assign, nonatomic) IBInspectable BOOL resignReturn;


@property (nonatomic, copy) BOOL(^shouldBeginEditingBlock)(YLTextField *);
@property (nonatomic, copy) void(^didBeginEditingBlock)(YLTextField *);
@property (nonatomic, copy) BOOL(^shouldEndEditingBlock)(YLTextField *);
@property (nonatomic, copy) void(^didEndEditingBlock)(YLTextField *);
@property (nonatomic, copy) BOOL(^shouldChangeCharactersInRangeWithReplacementStringBlock)(YLTextField *, NSRange, NSString *);
@property (nonatomic, copy) BOOL(^shouldClearBlock)(YLTextField *);
@property (nonatomic, copy) BOOL(^shouldReturnBlock)(YLTextField *);

@property (nonatomic,assign) BOOL isVerificationCode;
@property (nonatomic,assign) BOOL isPayWord;
@property (nonatomic,assign) BOOL isMoblie;

@property (nonatomic,assign) BOOL isBuyNumber;
@property (nonatomic,assign) BOOL isPrice;

@property (nonatomic,assign) BOOL isNormal;
@property (nonatomic,assign) BOOL isAvailable;



@end
