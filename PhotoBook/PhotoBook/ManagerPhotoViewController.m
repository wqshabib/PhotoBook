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


@property (strong, nonatomic) NSMutableArray<PhotoCellData*> *photos;
@property (nonatomic,strong) NSMutableArray *selectFlagArray;

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
        for (UIImage *img in images) {
            PhotoCellData *p = [[PhotoCellData alloc]init];
            p.image = img;
            [self.photos addObject:p];
        }
        [self syncAndSetSelectedAllNo];
        [self.photoCollectionView reloadData];
        // 上传照片
//        [self postUpLoadPhoto];
    }];
    //调用相册
    [ac showPreviewAnimated:YES];
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
    UIBarButtonItem *msgItemBtn = [[UIBarButtonItem alloc] initWithCustomView:editButton];
    [self.navigationItem setRightBarButtonItem:msgItemBtn];
    self.editButton = editButton;
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


-(void)postUpLoadPhoto {
    for (PhotoCellData *p in self.photos) {
        UIImage *originImage = p.image;
        __block NSInteger idx = [self.photos indexOfObject:p];
        NSData *data = UIImagePNGRepresentation(originImage);
        NSString *base64String = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        NSString *lastBase64 = FORMAT(@"%@%@",@"data:image/png;base64,",base64String);
        WEAK(self)
        [YLHttpTool POST:UPLOAD_PHOTO params:@{@"platTag":@"941in",@"img":lastBase64}
        success:^(NSDictionary *JSON){
        STRONG(self)
        NSLog(@"%@",JSON);
        // 附着信息源
        PKPhotoResponse *resp = (PKPhotoResponse*)[PKPhotoResponse toModel:JSON];
        if (resp.status == 0) {
            PhotoCellData *data =  self.photos[idx];
            data.data = resp.data;
        }
        } failure:^(NSError *error) {
            
        }];
    }
}




@end
