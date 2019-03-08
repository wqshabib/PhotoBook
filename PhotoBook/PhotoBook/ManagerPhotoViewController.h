//
//  ManagerPhotoViewController.h
//  PhotoBook
//
//  Created by sino on 2019/2/26.
//  Copyright © 2019 sino. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ManagerPhotoViewController : UIViewController

typedef void (^ManagerPhotoChooseOnePhoto)(PhotoCellData *data);

@property (nonatomic,copy) ManagerPhotoChooseOnePhoto chooseOnePhoto;


typedef void (^ManagerPhotoChooseOnePhotoImage)(UIImage *image);

@property (nonatomic,copy) ManagerPhotoChooseOnePhotoImage chooseOnePhotoImage;

@property (nonatomic,assign) BOOL isPick;

@end

NS_ASSUME_NONNULL_END
