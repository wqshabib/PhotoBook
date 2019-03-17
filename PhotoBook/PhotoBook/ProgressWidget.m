//
//  ProgressWidget.m
//  PhotoBook
//
//  Created by sino on 2019/3/12.
//  Copyright © 2019 sino. All rights reserved.
//

#import "ProgressWidget.h"
#import "HWProgressView/HWWaveView.h"

@interface ProgressWidget ()

@property (nonatomic,strong) HWWaveView *waveView;

@end

@implementation ProgressWidget

-(void)inital {
    CGFloat waveWidth = 150;
    CGFloat x = (self.bounds.size.width - 150)/2;
    CGFloat y = (self.bounds.size.height - 150)/2;
    CGRect bounds = CGRectMake(x, y, waveWidth, waveWidth);
    HWWaveView *waveView = [[HWWaveView alloc] initWithFrame:bounds];
    [self addSubview:waveView];
    self.waveView = waveView;
    self.hidden = YES;
    self.waveView.progress = 0;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self = [[[NSBundle mainBundle] loadNibNamed:@"ProgressWidget" owner:self options:nil] lastObject];
    if (self) {
        self.frame = frame;
    }
    return self;
}

-(void)show {
    self.hidden = NO;
}

-(void)hide{
    self.hidden = YES;
}

-(void)progress:(CGFloat)progress{
    self.waveView.progress = progress;
}

-(void)title:(NSString*)title {
//    self.labelTile.text = title;
    self.lbLine1.text = title;
}


@end
