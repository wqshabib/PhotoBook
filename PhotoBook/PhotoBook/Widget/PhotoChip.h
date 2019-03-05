//
//  PhotoChip.h
//  PhotoBook
//
//  Created by sino on 2019/3/5.
//  Copyright © 2019 sino. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YLImageView.h"
#import "YLButton.h"


@interface PhotoChip : UIView

@property (nonatomic,strong) UIView *alaphBackView;
@property (nonatomic,strong) UIImageView *iconAdd;
@property (nonatomic,strong) YLImageView *photoImageView;
@property (nonatomic,strong) YLImageView *borderImageView;
@property (nonatomic,strong) YLButton *button;

- (id)initWithFrame:(CGRect)frame realFrame:(CGRect)realFrame;

-(void)addRealPhoto:(NSString*)imageUrl;

-(void)addBorderImage:(NSString*)imageUrl;

-(void)roate:(NSNumber*)angle;

@end


