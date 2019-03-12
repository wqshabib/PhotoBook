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

@property (nonatomic,strong) UILabel *labelTile;

@end

@implementation ProgressWidget


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        HWWaveView *waveView = [[HWWaveView alloc] initWithFrame:CGRectMake(30, 100, 150, 150)];
        [self addSubview:waveView];
        self.waveView = waveView;
        self.hidden = YES;
        self.waveView.progress = 0;
        
        self.labelTile = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 300, 100)];
        self.labelTile.center = self.center;
        self.labelTile.text = @"";
        self.labelTile.textColor = [UIColor blackColor];
        self.labelTile.font = [UIFont systemFontOfSize:22.0];
        [self addSubview:self.labelTile];
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
    self.labelTile.text = title;
}

@end
