//
//  ProgressWidget.h
//  PhotoBook
//
//  Created by sino on 2019/3/12.
//  Copyright © 2019 sino. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProgressWidget : UIView

-(void)show;

-(void)hide;

-(void)progress:(CGFloat)progress;

-(void)title:(NSString*)title;
@end

NS_ASSUME_NONNULL_END
