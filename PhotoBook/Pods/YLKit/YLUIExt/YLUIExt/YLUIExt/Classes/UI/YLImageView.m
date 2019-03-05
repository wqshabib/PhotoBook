#import "YLImageView.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation YLImageView

-(void)setImageUrl:(NSString *)imageUrl {
    UIImage *placeHolder = [UIImage imageNamed:self.imageHolder];
    [self sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:placeHolder ? placeHolder : self.image];
}

-(void)setImageHolder:(NSString *)imageHolder {
    _imageHolder = imageHolder;
    self.image = [UIImage imageNamed:imageHolder];
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

-(void)getImageSize:(NSString*)url callBack:(YLImageViewRatioCallBack)callBack {
    [self sd_setImageWithURL:[NSURL URLWithString:url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL)
    {
        if (error) {
            BLOCK_EXEC(callBack,NO,0);
            return;
        }
        CGSize size = image.size;
        CGFloat radio = size.width / size.height;
        BLOCK_EXEC(callBack,YES,radio);
    }];
}


@end
