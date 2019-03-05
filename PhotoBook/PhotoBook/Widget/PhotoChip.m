//
//  PhotoChip.m
//  PhotoBook
//
//  Created by sino on 2019/3/5.
//  Copyright © 2019 sino. All rights reserved.
//

#import "PhotoChip.h"

@implementation PhotoChip

- (id)initWithFrame:(CGRect)frame realFrame:(CGRect)realFrame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        // 相片真实位置 带有偏移
        CGRect photoRealRect = realFrame;
        
        // 半透明黑色层
        UIView *alaphBackView = [[UIView alloc]initWithFrame:photoRealRect];
        alaphBackView.backgroundColor = COLORA(0, 0, 0, 0.6);
        [self addSubview:alaphBackView];
        self.alaphBackView = alaphBackView;
        
        // 小图标
        YLImageView *iconImageView = [[YLImageView alloc]initWithFrame:CGRectMake(0, 0, 20, 20)];
        iconImageView.image = [UIImage imageNamed:@"placeholder3"];
        [alaphBackView addSubview:iconImageView];
        iconImageView.center = [alaphBackView convertPoint:alaphBackView.center toView:alaphBackView];
        
        // 相片位置
        YLImageView *photoImageView = [[YLImageView alloc]initWithFrame:photoRealRect];
        [self addSubview:photoImageView];
        self.photoImageView = photoImageView;
        
        // 边框位置
        CGRect borderFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        YLImageView *borderImageView = [[YLImageView alloc]initWithFrame:borderFrame];
        [self addSubview:borderImageView];
        self.borderImageView = borderImageView;
        
        // 按钮位置
        YLButton *button = [YLButton buttonWithType:UIButtonTypeCustom];
        button.frame = borderFrame;
        [self addSubview:button];
        //[button addTarget:self action:@selector(onPressSelectLoc:) forControlEvents:UIControlEventTouchUpInside];
        self.button = button;
        
    }
    return self;
}

-(void)addRealPhoto:(NSString*)imageUrl {
    self.photoImageView.imageUrl = imageUrl;
}

-(void)addBorderImage:(NSString*)imageUrl{
    self.borderImageView.imageUrl = imageUrl;
}

-(void)roate:(NSNumber*)angle{
    double rotateAngle  = [angle doubleValue];
    double rotateRadian = rotateAngle / 180 * M_PI_2;
    self.transform = CGAffineTransformMakeRotation(rotateRadian);
}

@end
