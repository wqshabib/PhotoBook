//
//  PhotoCell.h
//  PhotoBook
//
//  Created by sino on 2019/2/26.
//  Copyright © 2019 sino. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YLImageView.h"
#import "YLButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface PhotoCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet YLImageView *photoImageView;
@property (weak, nonatomic) IBOutlet YLButton *button;
@property (weak, nonatomic) IBOutlet UIImageView *iconUnSelect;
@property (weak, nonatomic) IBOutlet UIImageView *iconSelect;

@property (assign,nonatomic) BOOL isHaveSelected;
@property (assign,nonatomic) BOOL isEdit;

@end

NS_ASSUME_NONNULL_END
