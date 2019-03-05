//
//  SummaryCell.h
//  PhotoBook
//
//  Created by sino on 2019/2/25.
//  Copyright © 2019 sino. All rights reserved.
//

#import "YLTableViewCell.h"
#import "YLImageView.h"
#import "YLButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface SummaryCell : YLTableViewCell

@property (weak, nonatomic) IBOutlet YLImageView *leftImageView;
@property (weak, nonatomic) IBOutlet YLImageView *rightImageView;
@property (weak, nonatomic) IBOutlet YLButton *button;

@end

NS_ASSUME_NONNULL_END
