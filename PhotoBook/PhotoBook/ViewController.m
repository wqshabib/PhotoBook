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
#import "UIView+Category.h"
#import "ProgressWidget.h"
#import "NSDictionary+Category.h"
#import "NSArray+Category.h"
#import "ToolCell.h"
#import "FCAlertView.h"

#define URL_INIT @"http://diy.h5.keepii.com/index.php?m=diy&a=init"

#define URL_Genearate @"http://diy.h5.keepii.com/index.php?m=diy&a=generate"

#define kProdSn @"20190222153837-3-4-13206737285c6fa6fdb03b32.42716265"

#define URL_UploadPreview @"http://diy.h5.keepii.com/index.php?m=upload&a=prodPreview"

#define URL_Save @"http://diy.h5.keepii.com/index.php?m=diy&a=save"

// http://diy.h5.keepii.com/photobook/#/?prodSn=20190222153837-3-4-13206737285c6fa6fdb03b32.42716265

@interface  CavasObject: NSObject

@end

@implementation CavasObject

@end

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate,
                            UICollectionViewDelegate,UICollectionViewDataSource,
                            TOCropViewControllerDelegate,FCAlertViewDelegate>

// 本地数据源
@property (nonatomic,strong) TemplateData *templateData;
// 大纲列表
@property (weak, nonatomic) IBOutlet YLTableView *summaryTableView;


// 相册控制器
@property (nonatomic,strong) ManagerPhotoViewController *managerPhotoVC;
// PhotoId
@property (nonatomic,assign) NSInteger selectPhotoId;

@property (strong, nonatomic) NSMutableArray<UIImage*> *previewImagesArray;

@property (nonatomic,strong) ProgressWidget *progressWidget;

@property (weak, nonatomic) IBOutlet UICollectionView *toolCollectionView;


// 重构尝试
@property (weak, nonatomic) IBOutlet UIView *editAreaView;
// 滚动视图
@property (nonatomic,strong) UIScrollView *scrollerView;


// 工作Paper
@property (nonatomic,strong) NSMutableArray<UIView*> *workSpaceViewArray;
// 工作Cavans
@property (nonatomic,strong) NSMutableArray<UIView*> *cavansArray;

// 获取页面总数
@property (nonatomic,assign) NSInteger paperCount;

// 缩放比例 0 - 1 .服务端画布 / 设备上比例
@property (nonatomic,assign) double paperToDeivceRatio;

// 当前页
@property (nonatomic,assign) NSInteger selectPaperIndex;

@end

@implementation ViewController

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    int pageNum = x / self.editAreaView.bounds.size.width;
    if (self.selectPaperIndex != pageNum) {
        self.selectPaperIndex = pageNum;
    }
}

-(void)setSelectPaperIndex:(NSInteger)selectPaperIndex {
    CGRect editArea = self.editAreaView.bounds;
    double w = editArea.size.width;
    _selectPaperIndex = selectPaperIndex;
    [self.scrollerView setContentOffset:CGPointMake(selectPaperIndex * w, 0) animated: YES];
    [self.summaryTableView setContentOffset:CGPointMake(0, 100 * selectPaperIndex) animated:YES];
}

-(NSInteger)paperCount {
    return self.templateData.tmplData.count;
}

-(double)paperToDeivceRatio {
    if (self.templateData.tmplData.count == 0) {
        return 1;
    }
    TmplData *tmpData  = self.templateData.tmplData.firstObject;
    Paper *paper = tmpData.paper;
    double pw = [paper.width doubleValue];
    double workSpaceW = self.editAreaView.bounds.size.width;
    return (workSpaceW / pw);
}

-(void)createPagesInScrollows {
    CGRect editArea = self.editAreaView.bounds;
    self.scrollerView = [[UIScrollView alloc]initWithFrame:editArea];
    self.scrollerView.pagingEnabled = YES;
    self.scrollerView.showsHorizontalScrollIndicator = NO;
    self.scrollerView.showsVerticalScrollIndicator = NO;
    self.scrollerView.delegate = self;
    [self.editAreaView addSubview:self.scrollerView];
    self.workSpaceViewArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < self.paperCount; i++) {
        UIView *paperView  = [[UIView alloc]initWithFrame:CGRectMake(editArea.size.width * i, 0,
                                                                     editArea.size.width, editArea.size.height)];
        
        paperView.backgroundColor = [UIColor clearColor];
        [self.workSpaceViewArray addObject:paperView];
        [self.scrollerView addSubview:paperView];
    }
    [self.scrollerView setContentSize:CGSizeMake(editArea.size.width *self.paperCount , editArea.size.height)];
    [self createCavans];
}


-(void)createCavans {
    
    self.cavansArray = [[NSMutableArray alloc]init];
    
    for (int i = 0 ; i < self.paperCount ;i++) {
        Paper *paper = self.templateData.tmplData[i].paper;
        double deviceW = [paper.width doubleValue]  * self.paperToDeivceRatio;
        double deviceH = [paper.height doubleValue] * self.paperToDeivceRatio;
        
        UIView *workSpaceView = self.workSpaceViewArray[i];
        double workH = workSpaceView.bounds.size.height;
        double y = (workH -  deviceH) / 2;
        
        CGRect cavasBounds = CGRectMake(0, y,deviceW,deviceH);
        UIView *canvas = [[UIView alloc]initWithFrame:cavasBounds];
        [workSpaceView addSubview:canvas];
        canvas.backgroundColor = [UIColor clearColor];
        [self.cavansArray addObject:canvas];
        
        
        double pageWidth = cavasBounds.size.width /  paper.page.count;
        
        for (int k = 0; k < paper.page.count ; k++) {
            Page *page = paper.page[k];
            CGRect pageRect = CGRectMake(pageWidth*k,0, pageWidth,cavasBounds.size.height);
            UIView *pageBack = [[UIView alloc]initWithFrame:pageRect];
            pageBack.backgroundColor = [UIColor clearColor];
            [canvas addSubview:pageBack];
            
            YLImageView *bgImageView = [[YLImageView alloc]initWithFrame:CGRectMake(0, 0, pageRect.size.width, pageRect.size.height)];
            bgImageView.imageUrl = page.data.bg.image;
            [pageBack addSubview:bgImageView];
            
            Data *data = page.data;
            for (int k = 0; k < data.photos.count ; k++) {
                Photos *photo = data.photos[k];
                
                CGRect miniRectFrame = [self toMiniRect:[self getPhotoChipRawRect:photo] ratio:self.paperToDeivceRatio];
                CGRect miniRealRectFrame = [self toMiniRect:[self getRealPhotoOffSetRawRect:photo] ratio:self.paperToDeivceRatio];
                
                PhotoChip *chip = [[PhotoChip alloc]initWithFrame:miniRectFrame realFrame:miniRealRectFrame];
                chip.backgroundColor = [UIColor clearColor];
                [pageBack addSubview:chip];
                
                if (photo.originalImage != nil) {
                    chip.photoImageView.image = [photo.originalImage imageByCropToRect:
                                                 [self caculateRect:photo image:photo.originalImage]];
                }
                
                [chip addBorderImage:photo.image];
                [chip roate:photo.rotate];
                chip.button.tag = photo.photoId;
                
                WEAK(self)
                chip.button.onPress = ^(YLButton *button) {
                    STRONG(self)
                    self.selectPhotoId = button.tag;
                    [self onPressSelectLoc:button];
                };
            }
        }
    }
}

-(void)updateAllCavas {
    for (int i = 0; i < self.cavansArray.count; i++) {
        [self updateCavas:i];
    }
}
-(void)updateCavas:(NSInteger)pageIndex {
    
    UIView *canvas = self.cavansArray[pageIndex];
    [canvas.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    Paper *paper = self.templateData.tmplData[pageIndex].paper;
    
    double deviceW = [paper.width doubleValue]  * self.paperToDeivceRatio;
    double deviceH = [paper.height doubleValue] * self.paperToDeivceRatio;
    
    UIView *workSpaceView = self.workSpaceViewArray[pageIndex];
    double workH = workSpaceView.bounds.size.height;
    double y = (workH -  deviceH) / 2;
    
    CGRect cavasBounds = CGRectMake(0, y,deviceW,deviceH);
    
  
    double pageWidth = cavasBounds.size.width /  paper.page.count;
    for (int k = 0; k < paper.page.count ; k++) {
        Page *page = paper.page[k];
        CGRect pageRect = CGRectMake(pageWidth*k,0, pageWidth,cavasBounds.size.height);
        UIView *pageBack = [[UIView alloc]initWithFrame:pageRect];
        pageBack.backgroundColor = [UIColor clearColor];
        [canvas addSubview:pageBack];
        
        YLImageView *bgImageView = [[YLImageView alloc]initWithFrame:CGRectMake(0, 0, pageRect.size.width, pageRect.size.height)];
        bgImageView.imageUrl = page.data.bg.image;
        [pageBack addSubview:bgImageView];
        
        Data *data = page.data;
        for (int k = 0; k < data.photos.count ; k++) {
            Photos *photo = data.photos[k];
            
            CGRect miniRectFrame = [self toMiniRect:[self getPhotoChipRawRect:photo] ratio:self.paperToDeivceRatio];
            CGRect miniRealRectFrame = [self toMiniRect:[self getRealPhotoOffSetRawRect:photo] ratio:self.paperToDeivceRatio];
            
            PhotoChip *chip = [[PhotoChip alloc]initWithFrame:miniRectFrame realFrame:miniRealRectFrame];
            chip.backgroundColor = [UIColor clearColor];
            [pageBack addSubview:chip];
            
            if (photo.originalImage != nil) {
                chip.photoImageView.image = [photo.originalImage imageByCropToRect:
                                             [self caculateRect:photo image:photo.originalImage]];
            }
            
            [chip addBorderImage:photo.image];
            [chip roate:photo.rotate];
            chip.button.tag = photo.photoId;
            
            WEAK(self)
            chip.button.onPress = ^(YLButton *button) {
                STRONG(self)
                self.selectPhotoId = button.tag;
                [self onPressSelectLoc:button];
            };
        }
    }
    
}

-(void)initPreviews {
    self.previewImagesArray = [[NSMutableArray alloc]init];
    for (int i = 0; i< self.templateData.tmplData.count ;i++ ) {
        UIImage *image = [[UIImage alloc]init];
        [self.previewImagesArray addObject:image];
    }
}

-(void)updateSummeryTable {
    for (int i = 0; i < self.cavansArray.count; i++) {
        UIView *cavas = self.cavansArray[i];
        UIImage *image = self.previewImagesArray[i];
        image = [cavas convertToImage];
        self.previewImagesArray[i] = image;
    }
    [self.summaryTableView reloadData];
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
    
    self.progressWidget = [[ProgressWidget alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:self.progressWidget];
    
    self.toolCollectionView.delegate = self;
    self.toolCollectionView.dataSource = self;
    
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
            // TODO ... Toast...
            return;
        }
        self.templateData = resp.data;
        // 重新排序
        self.templateData = [self sortTemplateData];
        // 打标签
        self.templateData = [self addPhotoIdToPhotos];
        
        if (self.templateData.tmplData.count > 0) {
            self.selectPaperIndex = 0;
        }
        
        [self createPagesInScrollows];
        [self initPreviews];
        [self updateSummeryTable];
    
    } failure:^(NSError *error) {
        // TODO ..Toast...
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
    
    cell.previewImageView.image = nil;
    UIImage *previewImage = self.previewImagesArray[indexPath.row];
    if (previewImage) {
        cell.previewImageView.image = previewImage;
    }
    
    if (paper.page.count  == 1) {
        Page *page = paper.page.firstObject;
        cell.lbPageNumber.text = FORMAT(@"%@",page.text);
    }
    else if (paper.page.count  == 2){
        Page *fpage = paper.page.firstObject;
        Page *lpage = paper.page.lastObject;
        cell.lbPageNumber.text = FORMAT(@"%@-%@",fpage.text,lpage.text);
    }
    
    // 大纲点击切换
    WEAK(self)
    cell.button.onPress = ^(YLButton *button) {
        STRONG(self)
        self.selectPaperIndex = indexPath.row;
    };
    return cell;
}

- (void)setupNavBarButtons {
    UIButton *albulmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    albulmButton.frame = CGRectMake(0, 0, 40, 20);
    [albulmButton setTitle:@"相册" forState:UIControlStateNormal];
    albulmButton.backgroundColor = [UIColor clearColor];
    [albulmButton addTarget:self action:@selector(onEnterAlbum) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *albulmButtonItem = [[UIBarButtonItem alloc] initWithCustomView:albulmButton];
    [self.navigationItem setRightBarButtonItems:@[albulmButtonItem]];
}


-(void)buildUpPreViewImage {
    
}

-(void)onEnterAlbum {
    [self pushToPhotoManager:NO photoId:0];
}


-(void)pushToPhotoManager:(BOOL)isPick photoId:(NSInteger)photoId {
    if (self.managerPhotoVC == nil) {
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.managerPhotoVC =  [story instantiateViewControllerWithIdentifier:@"ManagerPhotoViewController"];
    }
    self.managerPhotoVC.isPick = isPick;
    [self.navigationController pushViewController:self.managerPhotoVC animated:YES];
    [self handleChooseOnePhotoImage:photoId];
    [self handleAutoFill];
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
    
    WEAK(self)
    self.managerPhotoVC.chooseOnePhotoImage = ^(PhotoCellData *celldata) {
        STRONG(self)
        Photos * photo = [self findPhotoWithPhotoId:photoId];
        photo = [self decoratePhotosWithCellData:photo celldata:celldata];
        [self writePhotosWithId:photoId editPhoto:photo];
        CGRect defaultCropRect =[self caculateRect:photo image:celldata.image];
        TOCropViewController *cropController = [[TOCropViewController alloc] initWithCroppingStyle:TOCropViewCroppingStyleDefault image:celldata.image];
        cropController.delegate = self;
        cropController.angle = 0;
        cropController.imageCropFrame = defaultCropRect;
        cropController.aspectRatioLockEnabled = YES;
        cropController.resetButtonHidden = YES;
        cropController.aspectRatioPickerButtonHidden = YES;
        cropController.customAspectRatio = CGSizeMake(defaultCropRect.size.width, defaultCropRect.size.height);
        [self presentViewController:cropController animated:YES completion:nil];
    };
}


-(void)handleAutoFill {
    NSArray *idArrays = [self getPhotosIds];
    if (idArrays.count == 0) {
        return;
    }
    WEAK(self)
    self.managerPhotoVC.autoFill = ^(NSMutableArray<PhotoCellData *> * _Nonnull cellDatas) {
        STRONG(self)
        for (int i = 0; i < cellDatas.count ; i++) {
            PhotoCellData *data = cellDatas[i];
            NSInteger photoId = [idArrays[i] intValue];
            Photos * photo = [self findPhotoWithPhotoId:photoId];
            photo.originalImage = data.image;
            photo = [self decoratePhotosWithCellData:photo celldata:data];
            CGRect defaultCropRect =[self caculateRect:photo image:data.image];
            photo = [self decoratePhotosWithCropRect:photo cropRect:defaultCropRect angle:0];
        }
        [self updateAllCavas];
        [self updateSummeryTable];
        [self.navigationController popViewControllerAnimated:YES];
    };
}


-(Photos*)decoratePhotosWithCellData:(Photos*)photos celldata:(PhotoCellData*)celldata {
    photos.sourceImg.imgId      = celldata.data.imgId;
    photos.sourceImg.imgSrc     = celldata.data.imgUrl;
    photos.sourceImg.rwidth     = @(celldata.image.size.width);
    photos.sourceImg.rheight    = @(celldata.image.size.height);
    return photos;
}

-(Photos*)decoratePhotosWithCropRect:(Photos*)photos cropRect:(CGRect)cropRect angle:(NSInteger)angle {
    photos.sourceImg.sx = @(cropRect.origin.x);
    photos.sourceImg.sy = @(cropRect.origin.y);
    photos.sourceImg.swidth = @(cropRect.size.width);
    photos.sourceImg.sheight = @(cropRect.size.height);
    photos.sourceImg.rotate = @(angle);
    return photos;
}


#pragma mark - Cropper Delegate -
- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle {
    
    Photos * photo = [self findPhotoWithPhotoId:self.selectPhotoId];
    photo.originalImage = image;
    photo = [self decoratePhotosWithCropRect:photo cropRect:cropRect angle:angle];
    [self writePhotosWithId:self.selectPhotoId editPhoto:photo];
    WEAK(self)
    [cropViewController dismissViewControllerAnimated:YES completion:^{
        STRONG(self)
        [self updateUI];
    }];
}


-(void)updateUI {
    [self updateCavas:self.selectPaperIndex];
    [self updateSummeryTable];
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



-(void)postUploadPreViewPhoto:(NSArray<UIImage *>*)images {
    
    __block CGFloat step  = 0.9 /  images.count;
    
    NSString *msg = FORMAT(@"正在上传  1 / %d 张预览图",(int)images.count);
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
            
            NSString *msg = FORMAT(@"正在上传  %d / %d 张缩略图",i+1,(int)images.count);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressWidget title:msg];
            });
            NSData *data = UIImagePNGRepresentation(p.image);
            NSString *base64String = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            NSString *lastBase64 = FORMAT(@"%@%@",@"data:image/png;base64,",base64String);
            WEAK(self)
            [YLHttpTool POST:URL_UploadPreview params:@{@"prodSn":self.templateData.prodSn,@"img":lastBase64} success:^(NSDictionary *JSON){
                STRONG(self)
                dispatch_semaphore_signal(semaphore);
                NSLog(@"--------上传成功 i = %i",i);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressWidget progress:0.1 + step*(i+1)];
                });
                
                // 附着信息源
                PreviewResponse *resp = (PreviewResponse*)[PreviewResponse toModel:JSON];
                if (resp.status == 0) {
                    NSString *preUrl = resp.data.imgUrl;
                    NSLog(@"成功返回预览图地址: %@",preUrl);
                    
                    // 拼接上previewImage
                    Paper *paper =   self.templateData.tmplData[i].paper;
                    paper.previewImage = [preUrl copy];
                    self.templateData.tmplData[i].paper = paper;
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
                [self postSavewToServer];
            });
            
        });
    });
    
}

-(void)postSavewToServer {
//    Papers *papers = [[Papers alloc]init];
//    papers.papers = [[NSArray alloc]init];
    
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for (TmplData *sigleData in self.templateData.tmplData) {
        Paper *paper = sigleData.paper;
        [array addObject:paper];
    }
//    papers.papers = (NSArray*)array;
    
    NSDictionary *map = [self.templateData toDict];
    NSArray *mapPapers = map[@"tmplData"];
    NSString *prodData = [mapPapers transToJSONString];
    
    WEAK(self)
    [YLHttpTool POST:URL_Save params:@{@"prodSn":self.templateData.prodSn,
                                       @"prodData":prodData,
                                       } success:^(NSDictionary *JSON) {
        STRONG(self)
        Response *resp = (Response*)[Response toModel:JSON];
        if(resp.status == 0) {
            [self showSaveSuccess];
        }
        else {
            [self showError];
        }
    } failure:^(NSError *error) {
         [self showError];
    }];
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 5;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ToolCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ToolCell" forIndexPath:indexPath];
    NSInteger item = indexPath.item;
    
    if (item == 0) {
        cell.iconMenu.image = IMAGE(@"tool_z.png");
        cell.lbMenuName.text = @"撤销";
        WEAK(self)
        cell.buton.onPress = ^(YLButton *button) {
            STRONG(self)
            
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                cell.backView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            } completion:^(BOOL ok){
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    cell.backView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished){
                    [self undo];
                }];
            }];
            
        };
    }
    else if (item == 1) {
        cell.iconMenu.image = IMAGE(@"tool_rz.png");
        cell.lbMenuName.text = @"恢复";
        WEAK(self)
        cell.buton.onPress = ^(YLButton *button) {
            STRONG(self)
            
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                cell.backView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            } completion:^(BOOL ok){
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    cell.backView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished){
                      [self redo];
                }];
            }];
        };
    }
    else if (item == 2) {
        cell.iconMenu.image = IMAGE(@"tool_move.png");
        cell.lbMenuName.text = @"移动";
        WEAK(self)
        cell.buton.onPress = ^(YLButton *button) {
            STRONG(self)
            
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                cell.backView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            } completion:^(BOOL ok){
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    cell.backView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished){
                    [self move];
                }];
            }];
            
        };
    }
    else if (item == 3) {
        cell.iconMenu.image = IMAGE(@"tool_photo.png");
        cell.lbMenuName.text = @"相册";
        WEAK(self)
        cell.buton.onPress = ^(YLButton *button) {
            STRONG(self)
            
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                cell.backView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            } completion:^(BOOL ok){
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    cell.backView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished){
                    [self openPhoto];
                }];
            }];
            
        };
    }
    else if (item == 4) {
        cell.iconMenu.image = IMAGE(@"tool_save.png");
        cell.lbMenuName.text = @"保存";
        WEAK(self)
        cell.buton.onPress = ^(YLButton *button) {
            STRONG(self)
            
            
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                cell.backView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            } completion:^(BOOL ok){
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    cell.backView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished){
                    [self save];
                }];
            }];
            
           
        };
    }
    return cell;
}


-(void)undo {
    
    
}

-(void)redo {
    
}

-(void)move {
    
}

-(void)openPhoto {
    [self pushToPhotoManager:NO photoId:0];
}

-(void)save {
    FCAlertView *alert = [[FCAlertView alloc] init];
    alert.delegate = self;
    alert.tag = 1000;
    [alert makeAlertTypeCaution];
    [alert showAlertInView:self
                 withTitle:@"提示"
              withSubtitle:@"主人～ 您的作品已完成,保存并上传作品 ? "
           withCustomImage:nil
       withDoneButtonTitle:@"确定上传"
                andButtons:@[@"再等等"]];
    
    
}

- (void) FCAlertView:(FCAlertView *)alertView clickedButtonIndex:(NSInteger)index buttonTitle:(NSString *)title {
    if ([title isEqualToString:@"确定上传"]) {
        [self postUploadPreViewPhoto:self.previewImagesArray];
    }
    else if ([title isEqualToString:@"再等等"]) {
        // Perform Action for Button 2
    }
    else if ([title isEqualToString:@"重试"]) {
        [self postUploadPreViewPhoto:self.previewImagesArray];
    }
}

- (void)FCAlertDoneButtonClicked:(FCAlertView *)alertView {
    // 首次上传
    if (alertView.tag == 1000) {
        [self postUploadPreViewPhoto:self.previewImagesArray];
    }
    // 重试
    else if (alertView.tag == 3000) {
        [self postUploadPreViewPhoto:self.previewImagesArray];
    }
}

-(void)showSaveSuccess {
    FCAlertView *alert = [[FCAlertView alloc] init];
    alert.delegate = self;
    alert.tag = 2000;
    [alert makeAlertTypeSuccess];
    [alert showAlertInView:self
                 withTitle:@"恭喜"
              withSubtitle:@"作品保存成功!"
           withCustomImage:nil
       withDoneButtonTitle:@"朕知道了"
                andButtons:nil];
}

-(void)showError {
    FCAlertView *alert = [[FCAlertView alloc] init];
    alert.delegate = self;
    alert.tag = 3000;
    [alert makeAlertTypeWarning];
    [alert showAlertInView:self
                 withTitle:@"很抱歉"
              withSubtitle:@"服务器刚刚开小差了,再上传一次 ? "
           withCustomImage:nil
       withDoneButtonTitle:@"重试"
                andButtons:@[@"取消"]];
}

//
-(NSArray*)getPhotosIds {
    NSMutableArray *tmp = [[NSMutableArray alloc]init];
    for (TmplData *tmplData in self.templateData.tmplData) {
        Paper *paper = tmplData.paper;
        for (int i = 0; i < paper.page.count ; i++) {
            Page *page = paper.page[i];
            Data *data = page.data;
            for (int k = 0; k < data.photos.count ; k++) {
                Photos *photo = data.photos[k];
                [tmp addObject:@(photo.photoId)];
            }
        }
    }
    return (NSArray*)tmp;
}

@end
