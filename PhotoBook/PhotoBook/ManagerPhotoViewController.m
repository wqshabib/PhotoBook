//
//  ManagerPhotoViewController.m
//  PhotoBook
//
//  Created by sino on 2019/2/26.
//  Copyright © 2019 sino. All rights reserved.
//

#import "ManagerPhotoViewController.h"
#import "YLButton.h"
#import "ZLPhotoActionSheet.h"
#import "PhotoCell.h"
#import "LXCollectionViewLeftOrRightAlignedLayout.h"
#import "YLAlertView.h"
#import "Model.h"
#import "ProgressWidget.h"
#import "ToolCell.h"
#import "FCAlertView.h"

#define UPLOAD_PHOTO @"http://diy.h5.keepii.com/index.php?m=upload&a=photo"

@interface ManagerPhotoViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,FCAlertViewDelegate>


// 相册
@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;
// 功能
@property (weak, nonatomic) IBOutlet UICollectionView *menuCollectionView;

@property (weak, nonatomic) IBOutlet YLButton *buttonAddPhoto;
@property (weak, nonatomic) IBOutlet YLButton *buttonDeletePhoto;


@property (weak, nonatomic) IBOutlet UIView *deleteView;
@property (weak, nonatomic) IBOutlet UIView *addView;

@property (assign, nonatomic)  BOOL isInEdit;

// Gridview数据类型
@property (strong, nonatomic) NSMutableArray<PhotoCellData*> *photos;
@property (nonatomic,strong)  NSMutableArray *selectFlagArray;

@property (nonatomic,strong) ProgressWidget *progressWidget;
@end

@implementation ManagerPhotoViewController

-(void)viewWillAppear:(BOOL)animated {
    self.isInEdit = NO;
    [self syncAndSetSelectedAllNo];
    self.addView.alpha = 1;
    self.deleteView.alpha = 0;
    [self.menuCollectionView reloadData];
    [self.photoCollectionView reloadData];
    [super viewWillAppear:animated];
}

-(void)syncAndSetSelectedAllNo {
    NSMutableArray *tmp = [[NSMutableArray alloc]init];
    for (int i = 0; i < self.photos.count; i++) {
        [tmp addObject:[NSNumber numberWithBool:NO]];
    }
    self.selectFlagArray = tmp;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.addView.alpha = 1;
    self.deleteView.alpha = 0;
    self.selectFlagArray = [[NSMutableArray alloc]init];
    
    
    self.isInEdit = NO;
    self.title = @"我的相册";
    self.photos = [[NSMutableArray alloc]init];
    self.photoCollectionView.delegate = self;
    self.photoCollectionView.dataSource = self;
    self.menuCollectionView.delegate = self;
    self.menuCollectionView.dataSource = self;
    
    
    self.progressWidget = [[ProgressWidget alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:self.progressWidget];
    
    WEAK(self)
    self.buttonAddPhoto.onPress = ^(YLButton *button) {
        STRONG(self)
        [self callApiSelectPhoto];
    };
    
    self.buttonDeletePhoto.onPress = ^(YLButton *button) {
        STRONG(self)
        NSInteger howMuch = [self howMuchPhotosSelected];
        if(howMuch ==0) {
            [YLAlertView showMessage:@"请先选择至少一张照片" inVC:self onSure:^{
            }];
            return;
        }
        WEAK(self)
        NSString *msg = FORMAT(@"是否确认从相册中删除%td张相片",howMuch);
        [YLAlertView showMessage:msg inVC:self onSure:^{
            STRONG(self)
            [self deleteIndexOfPhotos];
        }];
    };
//    [self setupNavBarButtons];
    [self setupBackButtonWithBlock:nil];
}


-(NSInteger)howMuchPhotosSelected{
    NSInteger res = 0;
    for (int i = 0; i < self.selectFlagArray.count; i++) {
        BOOL isSelected = [self.selectFlagArray[i] boolValue];
        if (isSelected) {
            res += 1;
        }
    }
    return res;
}

-(void)deleteIndexOfPhotos {
    
    NSMutableArray *willDeleteArray = [[NSMutableArray alloc]init];
    
    for (NSInteger i = 0; i < self.selectFlagArray.count; i++) {
        BOOL isSelected = [self.selectFlagArray[i] boolValue];
        if (isSelected) {
            [willDeleteArray addObject:FORMAT(@"%td",i)];
        }
    }
    
    for (NSInteger j = 0; j < willDeleteArray.count ; j++) {
        NSString *deleteStringIndex= [willDeleteArray objectAtIndex:j];
        NSInteger lastIndex = [deleteStringIndex intValue]-j;
        [self.photos removeObjectAtIndex:lastIndex];
    }
    
    [self syncAndSetSelectedAllNo];
    [self.photoCollectionView reloadData];
}

-(void)callApiSelectPhoto {
    ZLPhotoActionSheet *ac = [[ZLPhotoActionSheet alloc] init];
    //相册参数配置，configuration有默认值，可直接使用并对其属性进行修改
    ac.configuration.maxSelectCount = 20;
    ac.configuration.maxPreviewCount = 0;
    //如调用的方法无sender参数，则该参数必传
    ac.sender = self;
    //选择回调
    WEAK(self)
    [ac setSelectImageBlock:^(NSArray<UIImage *> * _Nonnull images, NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal) {
        //your codes
        STRONG(self)
        [self postUploadPhoto:images];
    }];
    //调用相册
    [ac showPreviewAnimated:YES];
}



// 批量上传图片
-(void)postUploadPhoto:(NSArray<UIImage *>*)images {
    __block CGFloat step  = 0.9 /  images.count;
    NSString *msg = FORMAT(@"正在上传  1 / %d 张相片",(int)images.count);
    [self.progressWidget show];
    [self.progressWidget progress:0];
    [self.progressWidget progress:0.1];
    [self.progressWidget title:msg];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSLog(@"请求开始");
    dispatch_group_async(group, queue, ^{
        for (int i = 0; i < images.count; i++) {
            PhotoCellData *p = [[PhotoCellData alloc]init];
            p.image = images[i];
            p.taskId = i;
            NSString *msg = FORMAT(@"正在上传  %d / %d 张相片",i+1,(int)images.count);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressWidget title:msg];
            });
            NSData *data = UIImagePNGRepresentation(p.image);
            NSString *base64String = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            NSString *lastBase64 = FORMAT(@"%@%@",@"data:image/png;base64,",base64String);
            WEAK(self)
            [YLHttpTool POST:UPLOAD_PHOTO params:@{@"platTag":@"941in",@"img":lastBase64} success:^(NSDictionary *JSON){
            STRONG(self)
            dispatch_semaphore_signal(semaphore);
            NSLog(@"--------上传成功 i = %i",i);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressWidget progress:0.1 + step*(i+1)];
            });
            // 附着信息源
            PKPhotoResponse *resp = (PKPhotoResponse*)[PKPhotoResponse toModel:JSON];
            if (resp.status == 0) {
                p.data = resp.data;
                NSLog(@"成功返回 %@",p.data);
        
                [self.photos addObject:p];
            }
            } failure:^(NSError *error) {
                NSLog(@"--------上传失败 i = %i",i);
                dispatch_semaphore_signal(semaphore);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressWidget progress:0.1 + step*(i+1)];
                });
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
    });
     WEAK(self)
    dispatch_group_notify(group, queue, ^{
        STRONG(self)
        dispatch_async(dispatch_get_main_queue(), ^{
             NSLog(@"----全部请求完毕---");
            [self.progressWidget progress:1];
            [self.progressWidget title:@"上传已完成"];
            GCD_AFTER(0.5, ^{
                [self.progressWidget hide];
                [self.progressWidget progress:0];
                [self syncAndSetSelectedAllNo];
                [self.photoCollectionView reloadData];
            });

        });
    });
}



- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if ([collectionView isEqual:self.photoCollectionView]) {
        PhotoCellData *celldata = self.photos[indexPath.row];
        PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
        cell.photoImageView.image = celldata.image;
        cell.isEdit = self.isInEdit;
        BOOL isSelected = [self.selectFlagArray[indexPath.row] boolValue];
        cell.isHaveSelected = isSelected;
        WEAK(self)
        cell.button.onPress = ^(YLButton *button) {
            STRONG(self)
            if (self.isPick == YES) {
                BLOCK_EXEC(self.chooseOnePhotoImage,celldata);
                [self.navigationController popViewControllerAnimated:YES];
                return;
            }
            
            BOOL isSelectedButton = [self.selectFlagArray[indexPath.row] boolValue];
            self.selectFlagArray[indexPath.row] = [NSNumber numberWithBool:!isSelectedButton];
            [self.photoCollectionView reloadData];
        };
        return cell;
    }
    else if ([collectionView isEqual:self.menuCollectionView]) {
        ToolCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ToolCell" forIndexPath:indexPath];
        NSInteger item = indexPath.item;
        if (item == 0) {
            if (!self.isInEdit) {
                cell.iconMenu.image = IMAGE(@"tool_delete.png");
                cell.lbMenuName.text = @"删除";
            }
            else {
                cell.iconMenu.image = IMAGE(@"tool_done.png");
                cell.lbMenuName.text = @"完成";
            }
            WEAK(self)
            cell.buton.onPress = ^(YLButton *button) {
                STRONG(self)
                
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    cell.backView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                } completion:^(BOOL ok){
                    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        cell.backView.transform = CGAffineTransformIdentity;
                    } completion:^(BOOL finished){
                        [self toolDelete];
                    }];
                }];
                
            };
        }
        else if (item == 1) {
            cell.iconMenu.image = IMAGE(@"tool_fill.png");
            cell.lbMenuName.text = @"填充";
            WEAK(self)
            cell.buton.onPress = ^(YLButton *button) {
                STRONG(self)
                
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    cell.backView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                } completion:^(BOOL ok){
                    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        cell.backView.transform = CGAffineTransformIdentity;
                    } completion:^(BOOL finished){
                        [self toolFill];
                    }];
                }];
            };
        }
        else if (item == 2) {
            cell.iconMenu.image = IMAGE(@"tool_hide.png");
            cell.lbMenuName.text = @"隐藏";
            WEAK(self)
            cell.buton.onPress = ^(YLButton *button) {
                STRONG(self)
                
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    cell.backView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                } completion:^(BOOL ok){
                    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        cell.backView.transform = CGAffineTransformIdentity;
                    } completion:^(BOOL finished){
                        [self toolShowAndHide];
                    }];
                }];
                
            };
        }
        return cell;
    }
    return [[UICollectionViewCell alloc]init];
    
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([collectionView isEqual:self.photoCollectionView]) {
        return self.photos.count;
    }
    else if ([collectionView isEqual:self.menuCollectionView]) {
        return 3;
    }
    return 0;
}

// 删除和完成
-(void)toolDelete {
    self.isInEdit = !self.isInEdit;
    [self.photoCollectionView reloadData];
    // 编辑状态
    if (self.isInEdit) {
        WEAK(self)
        [UIView animateWithDuration:0.5 animations:^{
            STRONG(self)
            self.addView.alpha = 0;
            self.deleteView.alpha = 1;
            [self.view layoutIfNeeded];
        }];
    }
    // 完成状态
    else {
        [self syncAndSetSelectedAllNo];
        WEAK(self)
        [UIView animateWithDuration:0.5 animations:^{
            STRONG(self)
            self.addView.alpha = 1;
            self.deleteView.alpha = 0;
            [self.view layoutIfNeeded];
        }];
    }
    [self.menuCollectionView reloadData];
}


-(void)toolShowAndHide {
 
}



-(void)toolFill {
    [self alertFill];
}



- (void)setupBackButtonWithBlock:(void(^)(void))backBlock {
    YLButton *backButton = [YLButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, 20, 30);
    [backButton setImage:[UIImage imageNamed:@"导航栏-返回"] forState:UIControlStateNormal];
    backButton.backgroundColor = [UIColor clearColor];
    [backButton addTarget:self action:@selector(onPressBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backButtonItem];
}

-(void)onPressBack {
    [self.navigationController popViewControllerAnimated:YES];
}



- (void) FCAlertView:(FCAlertView *)alertView clickedButtonIndex:(NSInteger)index buttonTitle:(NSString *)title {
    if ([title isEqualToString:@"确定"]) {
    }
    else if ([title isEqualToString:@"再等等"]) {
        
    }
}

- (void)FCAlertDoneButtonClicked:(FCAlertView *)alertView {
    if (alertView.tag == 4000) {
        [self actionFill];
    }
    if (alertView.tag == 5000) {
        [self callApiSelectPhoto];
    }
}

-(void)alertFill {
    
    if (self.photos.count == 0) {
        FCAlertView *alert = [[FCAlertView alloc] init];
        alert.delegate = self;
        alert.tag = 5000;
        [alert makeAlertTypeCaution];
        [alert showAlertInView:self
                     withTitle:@"提示"
                  withSubtitle:@"相册里一张相片都没有～ 去选出您喜欢的相片吧! "
               withCustomImage:nil
           withDoneButtonTitle:@"去选相片"
                    andButtons:@[@"再等等"]];
        return;
    }
    
    FCAlertView *alert = [[FCAlertView alloc] init];
    alert.delegate = self;
    alert.tag = 4000;
    [alert makeAlertTypeCaution];
    [alert showAlertInView:self
                 withTitle:@"提示"
              withSubtitle:@"是否确定使用自动填充 ? "
           withCustomImage:nil
       withDoneButtonTitle:@"确定"
                andButtons:@[@"再等等"]];
}


-(void)actionFill {
    BLOCK_EXEC(self.autoFill,self.photos);
}


@end
