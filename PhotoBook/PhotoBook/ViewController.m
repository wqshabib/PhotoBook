//
//  ViewController.m
//  PhotoBook
//
//  Created by sino on 2019/2/22.
//  Copyright © 2019 sino. All rights reserved.
//

#import "ViewController.h"
#import "YLTableView.h"
#import "SummaryCell.h"
#import "ManagerPhotoViewController.h"
#import "PhotoChip.h"
#import "UIImage+CropImage.h"
#import "TOCropViewController.h"

#define URL_INIT @"http://diy.h5.keepii.com/index.php?m=diy&a=init"

#define URL_Genearate @"http://diy.h5.keepii.com/index.php?m=diy&a=generate"

#define kProdSn @"20190222153837-3-4-13206737285c6fa6fdb03b32.42716265"

// http://diy.h5.keepii.com/photobook/#/?prodSn=20190222153837-3-4-13206737285c6fa6fdb03b32.42716265

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

// 本地数据源
@property (nonatomic,strong) TemplateData *templateData;
// 大纲列表
@property (weak, nonatomic) IBOutlet YLTableView *summaryTableView;
// 工作区
@property (weak, nonatomic) IBOutlet UIView *workSpaceView;
// 缩放比例 0 - 1
@property (nonatomic,assign) double ratio;
// 当前页
@property (nonatomic,assign) NSInteger selectPaperIndex;
// 当前页数据
@property (nonatomic,strong) Paper *selectPaper;
// 工作区宽度
@property (nonatomic,assign) CGRect workSpaceFrame;
// 画布宽
@property (nonatomic,assign) CGRect cavasFrame;
// 画布
@property (strong, nonatomic) UIView *cavas;
// 画布上的页
@property (strong, nonatomic) NSMutableArray<UIView*> *cavasPages;
// 相册控制器
@property (nonatomic,strong) ManagerPhotoViewController *managerPhotoVC;
// PhotoId
@property (nonatomic,assign) NSInteger selectPhotoId;

@end

@implementation ViewController


// 刷新界面
-(void)setState {
    [self addCanvas];
    [self addElement];
}

-(void)calculateRatio {
    Paper *paper = self.selectPaper;
    double pw = [paper.width doubleValue];
    if (pw == 0) {
        self.ratio = 1;
        return;
    }
    double workSpaceW = self.workSpaceFrame.size.width;
    self.ratio = workSpaceW / pw;
}

-(void)addCanvas {
    
    [[self.workSpaceView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    Paper *paper = self.selectPaper;
    double pw = [paper.width doubleValue];
    double ph = [paper.height doubleValue];
    
    CGRect cavasFrame = CGRectMake(0, 0, pw * self.ratio, ph * self.ratio);
    UIView *canvas = [[UIView alloc]initWithFrame:cavasFrame];
    [self.workSpaceView addSubview:canvas];
    canvas.backgroundColor = [UIColor clearColor];
    canvas.center = [self.workSpaceView convertPoint:self.workSpaceView.center fromView:self.workSpaceView];
    self.cavasFrame = canvas.frame;
    self.cavas = canvas;
}

-(CGRect)toMiniRect:(CGRect)rawRect ratio:(double)ratio{
    double rx = rawRect.origin.x;
    double ry = rawRect.origin.y;
    double rw = rawRect.size.width;
    double rh = rawRect.size.height;
    
    double x = rx * ratio;
    double y = ry * ratio;
    double w = rw * ratio;
    double h = rh * ratio;
    return CGRectMake(x ,y, w,h);
}

-(CGRect)getPhotoChipRawRect:(Photos*)photo{
    if (photo == nil) {
        return CGRectMake(0, 0, 0, 0);
    }
    double x = [photo.x doubleValue];
    double y = [photo.y doubleValue];
    double w = [photo.width doubleValue];
    double h = [photo.height doubleValue];
    return CGRectMake(x ,y, w,h);
}


-(CGRect)getRealPhotoOffSetRawRect:(Photos*)photo{
    if (photo == nil) {
        return CGRectMake(0, 0, 0, 0);
    }
    Offset *offset = photo.sourceImg.offset;
    double x = [offset.x doubleValue];
    double y = [offset.y doubleValue];
    double w = [offset.width doubleValue];
    double h = [offset.height doubleValue];
    return CGRectMake(x ,y, w,h);
}


-(void)addElement {
    CGRect cavasFrame = self.cavasFrame;
    Paper *paper = self.selectPaper;
    double perWidth = cavasFrame.size.width /  paper.page.count;
    double perHeight = cavasFrame.size.height;
    self.cavasPages = [[NSMutableArray alloc]init];
    
    for (int i = 0; i < paper.page.count ; i++) {
        Page *page = paper.page[i];
        CGRect pageRect = CGRectMake(perWidth*i,0, perWidth,perHeight);
        UIView *tmpView = [[UIView alloc]initWithFrame:pageRect];

        [self.cavasPages addObject:tmpView];
        [self.cavas addSubview:tmpView];
        
        YLImageView *bgImageView = [[YLImageView alloc]initWithFrame:CGRectMake(0, 0, pageRect.size.width, pageRect.size.height)];
        bgImageView.imageUrl = page.data.bg.image;
        [tmpView addSubview:bgImageView];
        
        Data *data = page.data;
        for (int k = 0; k < data.photos.count ; k++) {
            Photos *photo = data.photos[k];
            
            CGRect miniRectFrame = [self toMiniRect:[self getPhotoChipRawRect:photo] ratio:self.ratio];
            CGRect miniRealRectFrame = [self toMiniRect:[self getRealPhotoOffSetRawRect:photo] ratio:self.ratio];
            
            PhotoChip *chip = [[PhotoChip alloc]initWithFrame:miniRectFrame realFrame:miniRealRectFrame];
            [tmpView addSubview:chip];
            
            if (photo.originalImage != nil) {
               chip.photoImageView.image = [photo.originalImage imageByCropToRect:
                                            [self caculateRect:photo image:photo.originalImage]];
            }
            
            [chip addBorderImage:photo.image];
            [chip roate:photo.rotate];
            chip.button.tag = photo.photoId;
            
            NSLog(@"photoId = %06td",photo.photoId);
            
            WEAK(self)
            chip.button.onPress = ^(YLButton *button) {
                STRONG(self)
                self.selectPhotoId = button.tag;
                [self onPressSelectLoc:button];
            };
            
        }
    }
}

-(void)onPressSelectLoc:(YLButton*)button{
    
    // button.backgroundColor = COLORA(102,187,106,0.8);
    // 动画
    /*
    button.backgroundColor = [UIColor redColor];
    CABasicAnimation *an = [self opacityForeverAnimation:0.5];
    [button.layer addAnimation:an forKey:nil];
     */
    [self pushToPhotoManager:YES photoId:button.tag];
}

-(CABasicAnimation *)opacityForeverAnimation:(float)time {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];//必须写opacity才行。
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.0f];//这是透明度。
    animation.autoreverses = YES;
    animation.duration = time;
    animation.repeatCount = MAXFLOAT;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];///没有的话是均匀的动画。
    return animation;
}
    


- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectPaperIndex = 0;
    self.selectPhotoId = 0;
    [self setupNavBarButtons];
    [self initTable];
    [self requestInitData];
//    [self requestGenerate];
}

-(void)initTable{
    // 代理
    self.summaryTableView.delegate   = self;
    self.summaryTableView.dataSource = self;
}

-(void)requestInitData {
    WEAK(self)
    [YLHttpTool POST:URL_INIT params:@{@"prodSn":kProdSn} success:^(NSDictionary *JSON) {
        STRONG(self)
        TemplateResponse *resp = (TemplateResponse*)[TemplateResponse toModel:JSON];
        if (resp.status != 0) {
            return;
        }
        self.templateData = resp.data;
        // 重新排序
        self.templateData = [self sortTemplateData];
        // 打标签
        self.templateData = [self addPhotoIdToPhotos];
        
        NSLog(@"%@",self.templateData.prodSn);
        [self.summaryTableView reloadData];
        self.workSpaceFrame = self.workSpaceView.frame;
        
        if (self.templateData.tmplData.count > 0) {
            TmplData *data = self.templateData.tmplData[0];
            Paper *paper = data.paper;
            self.selectPaper = paper;
            self.selectPaperIndex = 0;
            [self calculateRatio];
            [self setState];
        }
    
    } failure:^(NSError *error) {
        //
    }];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.templateData.tmplData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TmplData *data = self.templateData.tmplData[indexPath.row];
    Paper *paper = data.paper;
    SummaryCell * cell = [tableView dequeueReusableCellWithIdentifier:@"SummaryCell"];
    if (paper.page.count >= 1) {
        Page *page = paper.page.firstObject;
        cell.leftImageView.imageUrl = page.data.bg.image;
    }
    if (paper.page.count  == 2) {
        Page *page = paper.page.lastObject;
        cell.rightImageView.imageUrl = page.data.bg.image;
    }
    // [cell.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cell.button setTitleColor:COLORA(0, 0, 0, 0.8) forState:UIControlStateNormal];
    cell.button.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    
    [cell.button setTitle:@"" forState:UIControlStateNormal];
    if (paper.page.count  == 1) {
        Page *page = paper.page.firstObject;
        NSString *text = FORMAT(@"%@",page.text);
        [cell.button setTitle:text forState:UIControlStateNormal];
    }
    else if (paper.page.count  == 2){
        Page *fpage = paper.page.firstObject;
        Page *lpage = paper.page.lastObject;
        NSString *text = FORMAT(@"%@-%@",fpage.text,lpage.text);
        [cell.button setTitle:text forState:UIControlStateNormal];
    }
    
    // 大纲点击切换
    WEAK(self)
    cell.button.onPress = ^(YLButton *button) {
        STRONG(self)
        TmplData *data = self.templateData.tmplData[indexPath.row];
        Paper *paper = data.paper;
        self.selectPaper = paper;
        self.selectPaperIndex = indexPath.row;
        [self calculateRatio];
        [self setState];
    };
    return cell;
}

- (void)setupNavBarButtons {
    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.frame = CGRectMake(0, 0, 40, 20);
    [moreButton setTitle:@"相册" forState:UIControlStateNormal];
    moreButton.backgroundColor = [UIColor clearColor];
    [moreButton addTarget:self action:@selector(onEnterAlbum) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *msgItemBtn = [[UIBarButtonItem alloc] initWithCustomView:moreButton];
    [self.navigationItem setRightBarButtonItem:msgItemBtn];
}

-(void)onEnterAlbum {
    [self pushToPhotoManager:NO photoId:0];
}


-(void)pushToPhotoManager:(BOOL)isPick photoId:(NSInteger)photoId {
    if (self.managerPhotoVC == nil) {
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.managerPhotoVC =  [story instantiateViewControllerWithIdentifier:@"ManagerPhotoViewController"];
        self.managerPhotoVC.isPick = isPick;
        [self.navigationController pushViewController:self.managerPhotoVC animated:YES];
        [self handleChooseOnePhotoImage:photoId];
    }
    else {
        self.managerPhotoVC.isPick = isPick;
        [self.navigationController pushViewController:self.managerPhotoVC animated:YES];
        [self handleChooseOnePhotoImage:photoId];
    }
  
}



-(CGRect)caculateRect:(Photos*)photo image:(UIImage*)photoImage{
    
    CGRect rectPhotos = [self getPhotoChipRawRect:photo];
    
    double photoDiv     = rectPhotos.size.width /  rectPhotos.size.height;
    
    double picWidth     = photoImage.size.width;
    double picHeight    = photoImage.size.height;
    double picDiv       = photoImage.size.width /  photoImage.size.height;
    
    double cropX = 0;
    double cropY = 0;
    double cropW = 0;
    double cropH = 0;
    
    // 图片中位 剪切 区域计算 （自适应）
    
    // 图片长宽比 > 相位长宽比 ，h = 图片高度, w = 截取中间
    if (picDiv > photoDiv) {
        cropH = picHeight;
        cropY = 0;
        cropW = picHeight * photoDiv;
        cropX = (picWidth - cropW) * 0.5;
    }
    // 图片长宽比 < 相位长宽比 ， w = 图片宽度 h 取中间部分
    else {
        cropW = picWidth;
        cropX = 0;
        cropH = picWidth / photoDiv;
        cropY = (picHeight - cropH) * 0.5;
    }
    return CGRectMake(cropX, cropY, cropW, cropH);
}

-(void)handleChooseOnePhotoImage:(NSInteger)photoId {
    
    Photos * photo = [self findPhotoWithPhotoId:photoId];
    
    WEAK(self)
    self.managerPhotoVC.chooseOnePhotoImage = ^(UIImage * _Nonnull image) {
        STRONG(self)
               
        CGRect cropRect =[self caculateRect:photo image:image];
        
        TOCropViewController *cropController = [[TOCropViewController alloc] initWithCroppingStyle:TOCropViewCroppingStyleDefault image:image];
        //           cropController.delegate = self;
        cropController.angle = 0;
        cropController.imageCropFrame = cropRect;
        cropController.aspectRatioLockEnabled = YES;
        cropController.resetButtonHidden = YES;
        cropController.aspectRatioPickerButtonHidden = YES;
        [self presentViewController:cropController animated:YES completion:nil];
    };
}



-(TemplateData*)sortTemplateData {
    for (TmplData *tmplData in self.templateData.tmplData) {
        for (Page *page in tmplData.paper.page) {
            NSArray *resArray  = [[NSArray alloc]init];
            NSArray *photos = page.data.photos;
            // 排序key, 某个对象的属性名称，是否升序, YES-升序, NO-降序
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"zIndex" ascending:YES];
            // 排序结果
            resArray= [photos sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            // 给回去
            page.data.photos = resArray;
        }
    }
    return self.templateData;
}


// 为每个photo打一个标志
-(TemplateData*)addPhotoIdToPhotos {
    for (int i = 0 ; i <  self.templateData.tmplData.count ; i++) {
        TmplData *tmplData =  self.templateData.tmplData[i];
        Paper *paper = tmplData.paper;
        for (int j = 0; j < paper.page.count ; j++) {
            Page *page = paper.page[j];
            Data *data = page.data;
            for (int k = 0; k < data.photos.count ; k++) {
                Photos *photo = data.photos[k];
                photo.photoId =  i *1000 + j * 100 + k;
                photo.isSelected = NO;
                NSLog(@"photoId TAG = %06td",photo.photoId);
            }
        }
    }
    return self.templateData;
}

-(Photos*)findPhotoWithPhotoId:(NSInteger)photoId{
    for (TmplData *tmplData in self.templateData.tmplData) {
        Paper *paper = tmplData.paper;
        for (int i = 0; i < paper.page.count ; i++) {
            Page *page = paper.page[i];
            Data *data = page.data;
            for (int k = 0; k < data.photos.count ; k++) {
                Photos *photo = data.photos[k];
                if (photo.photoId == photoId) {
                    return photo;
                }
            }
        }
    }
    return nil;
}

-(void)writePhotosWithId:(NSInteger)photoId editPhoto:(Photos*)editPhoto {
    for (TmplData *tmplData in self.templateData.tmplData) {
        Paper *paper = tmplData.paper;
        for (int i = 0; i < paper.page.count ; i++) {
            Page *page = paper.page[i];
            Data *data = page.data;
            for (int k = 0; k < data.photos.count ; k++) {
                Photos *photo = data.photos[k];
                if (photo.photoId == photoId) {
                    if (editPhoto) {
                        photo = editPhoto;
                    }
                }
            }
        }
    }
}
@end
