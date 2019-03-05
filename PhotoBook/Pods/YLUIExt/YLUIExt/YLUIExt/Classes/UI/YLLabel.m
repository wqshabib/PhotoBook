#import "YLLabel.h"

@implementation YLLabel

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
