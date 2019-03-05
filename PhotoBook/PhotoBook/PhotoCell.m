//
//  PhotoCell.m
//  PhotoBook
//
//  Created by sino on 2019/2/26.
//  Copyright © 2019 sino. All rights reserved.
//

#import "PhotoCell.h"

@implementation PhotoCell

-(void)setIsEdit:(BOOL)isEdit {
    _isEdit = isEdit;
    if (isEdit == NO) {
        self.iconSelect.hidden = YES;
        self.iconUnSelect.hidden = YES;
    }
}

-(void)setIsHaveSelected:(BOOL)isHaveSelected {
    _isHaveSelected = isHaveSelected;
    if (self.isEdit == NO) {
        self.iconSelect.hidden = YES;
        self.iconUnSelect.hidden = YES;
    }
    else {
        self.iconSelect.hidden = !isHaveSelected;
        self.iconUnSelect.hidden = isHaveSelected;
    }

}
@end
