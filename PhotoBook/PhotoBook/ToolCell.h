//
//  ToolCell.h
//  PhotoBook
//
//  Created by sino on 2019/3/15.
//  Copyright © 2019 sino. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YLButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface ToolCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UILabel *lbMenuName;
@property (weak, nonatomic) IBOutlet YLButton *buton;
@property (weak, nonatomic) IBOutlet UIImageView *iconMenu;

@end

NS_ASSUME_NONNULL_END
