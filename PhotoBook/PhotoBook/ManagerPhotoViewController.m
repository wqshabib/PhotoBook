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

#define UPLOAD_PHOTO @"http://diy.h5.keepii.com/index.php?m=upload&a=photo"



@interface ManagerPhotoViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet YLButton *buttonAddPhoto;
@property (weak, nonatomic) IBOutlet YLButton *buttonDeletePhoto;
@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;
@property (weak, nonatomic) IBOutlet LXCollectionViewLeftOrRightAlignedLayout *layout;


@property (weak, nonatomic) IBOutlet UIView *deleteView;
@property (weak, nonatomic) IBOutlet UIView *addView;

@property (assign, nonatomic)  BOOL isInEdit;

@property (strong, nonatomic) UIButton *editButton;
@property (strong, nonatomic) UIButton *fillButton;
@property (strong, nonatomic) UIButton *hideButton;

// Gridview数据类型
@property (strong, nonatomic) NSMutableArray<PhotoCellData*> *photos;
@property (nonatomic,strong) NSMutableArray *selectFlagArray;

@property (nonatomic,strong) ProgressWidget *progressWidget;
@end

@implementation ManagerPhotoViewController

-(void)viewWillAppear:(BOOL)animated {
    
    self.isInEdit = NO;
    [self syncAndSetSelectedAllNo];
    
    self.addView.alpha = 1;
    self.deleteView.alpha = 0;
    
    if (self.editButton) {
        [self.editButton setTitle:@"选择" forState:UIControlStateNormal];
    }
    
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
    [self setupNavBarButtons];
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
            // 附着信息源
            PKPhotoResponse *resp = (PKPhotoResponse*)[PKPhotoResponse toModel:JSON];
            if (resp.status == 0) {
                p.data = resp.data;
                NSLog(@"成功返回 %@",p.data);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressWidget progress:0.1 + step*(i+1)];
                });
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
    PhotoCellData *PhotoCellData = self.photos[indexPath.row];
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    cell.photoImageView.image = PhotoCellData.image;
    cell.isEdit = self.isInEdit;
    BOOL isSelected = [self.selectFlagArray[indexPath.row] boolValue];
    cell.isHaveSelected = isSelected;
    WEAK(self)
    cell.button.onPress = ^(YLButton *button) {
        STRONG(self)
        if (self.isPick == YES) {
            BLOCK_EXEC(self.chooseOnePhotoImage,cell.photoImageView.image);
//            BLOCK_EXEC(self.chooseOnePhoto,PhotoCellData);
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
        
        BOOL isSelectedButton = [self.selectFlagArray[indexPath.row] boolValue];
        self.selectFlagArray[indexPath.row] = [NSNumber numberWithBool:!isSelectedButton];
        [self.photoCollectionView reloadData];
    };
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}



- (void)setupNavBarButtons {
    UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    editButton.frame = CGRectMake(0, 0, 40, 20);
    [editButton setTitle:@"选择" forState:UIControlStateNormal];
    editButton.backgroundColor = [UIColor clearColor];
    [editButton addTarget:self action:@selector(onPressEdit:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *fillButton = [UIButton buttonWithType:UIButtonTypeCustom];
    fillButton.frame = CGRectMake(0, 0, 40, 20);
    [fillButton setTitle:@"填充" forState:UIControlStateNormal];
    fillButton.backgroundColor = [UIColor clearColor];
    [fillButton addTarget:self action:@selector(onPressFill:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIBarButtonItem *editButtonItem = [[UIBarButtonItem alloc] initWithCustomView:editButton];
    UIBarButtonItem *fillButtonItem = [[UIBarButtonItem alloc] initWithCustomView:fillButton];
    
    [self.navigationItem setRightBarButtonItems:@[editButtonItem,fillButtonItem]];
    
    self.editButton = editButton;
    
}

-(void)onPressFill:(UIButton*)button {
    NSLog(@"Fill");
}






-(void)onPressEdit:(UIButton*)button {
    self.isInEdit = !self.isInEdit;
    [button setTitle:self.isInEdit ? @"完成" :@"选择" forState:UIControlStateNormal];
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






@end
