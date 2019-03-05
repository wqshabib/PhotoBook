#import <UIKit/UIKit.h>
#import <YLCore/YLMacro.h>
#import <YLCore/YLCallBackDefine.h>



@interface YLTextField : UITextField

@property (nonatomic,assign)  CGFloat cornerRadius;
@property (nonatomic,assign)  CGFloat borderWidth;
@property (nonatomic,copy)  UIColor *borderColor;
@property (nonatomic,assign)  BOOL isRound;

@property (nonatomic,assign)  NSUInteger placeFont;
@property (nonatomic,copy)  UIColor *placeColor;

@property (assign, nonatomic)  NSUInteger max;
@property (assign, nonatomic)  BOOL resignReturn;


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
