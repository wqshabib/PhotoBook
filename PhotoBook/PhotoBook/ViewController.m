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

#define URL_INIT @"http://diy.h5.keepii.com/index.php?m=diy&a=init"
#define kProdSn @"20190222153837-3-4-13206737285c6fa6fdb03b32.42716265"

// http://diy.h5.keepii.com/photobook/#/?prodSn=20190222153837-3-4-13206737285c6fa6fdb03b32.42716265

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

// 本地数据源
@property (nonatomic,strong) TemplateData *templateData;

@property (weak, nonatomic) IBOutlet YLTableView *summaryTableView;
@property (weak, nonatomic) IBOutlet UIView *workSpaceView;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolBarHeight;
@property (nonatomic,assign) BOOL isExpand;


@property (nonatomic,assign) double ratio;
@property (nonatomic,assign) NSInteger index;
@property (nonatomic,strong) Paper *selectPaper;

@property (nonatomic,assign) CGRect workSpaceFrame;

@property (nonatomic,assign) CGRect cavasFrame;

@property (strong, nonatomic) UIView *cavas;
@property (strong, nonatomic) NSMutableArray<UIView*> *cavasPages;

@property (nonatomic,strong) ManagerPhotoViewController *managerPhotoVC;

@end

@implementation ViewController


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
    canvas.backgroundColor = [UIColor redColor];
    canvas.center = [self.workSpaceView convertPoint:self.workSpaceView.center fromView:self.workSpaceView];
    self.cavasFrame = canvas.frame;
    self.cavas = canvas;
}

-(void)addBG {
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
        
        YLImageView *tmpImageView = [[YLImageView alloc]initWithFrame:CGRectMake(0, 0, pageRect.size.width, pageRect.size.height)];
        tmpImageView.imageUrl = page.data.bg.image;
        [tmpView addSubview:tmpImageView];
        
        Data *data = page.data;
        for (int k = 0; k < data.photos.count ; k++) {
            Photos *photo = data.photos[k];
            
            double photoRawW = [photo.width doubleValue];
            double photoRawH = [photo.height doubleValue];
            double photoRawX = [photo.x doubleValue];
            double photoRawY = [photo.y doubleValue];
            
            double photoRatioW = photoRawW * self.ratio;
            double photoRatioH = photoRawH * self.ratio;
            double photoRatioX = photoRawX * self.ratio;
            double photoRatioY = photoRawY * self.ratio;
            
            // 相位
            CGRect photoLocationRect = CGRectMake(photoRatioX ,photoRatioY, photoRatioW,photoRatioH);
            UIView *photoLocationView = [[UIView alloc]initWithFrame:photoLocationRect];
            photoLocationView.backgroundColor = [UIColor clearColor];
            [tmpView addSubview:photoLocationView];
            
       
            // 偏移量
            Offset *offset = photo.sourceImg.offset;
            
            double offsetRawW = [offset.width doubleValue];
            double offsetRawH = [offset.height doubleValue];
            double offsetRawX = [offset.x doubleValue];
            double offsetRawY = [offset.y doubleValue];
            
            double offsetRatioW = offsetRawW * self.ratio;
            double offsetRatioH = offsetRawH * self.ratio;
            double offsetRatioX = offsetRawX * self.ratio;
            double offsetRatioY = offsetRawY * self.ratio;
            // 真实照片
            CGRect photoRealRect = CGRectMake(offsetRatioX,offsetRatioY, offsetRatioW,offsetRatioH);
            UIView *photoRealView = [[UIView alloc]initWithFrame:photoRealRect];
            photoRealView.backgroundColor = COLORA(0, 0, 0, 0.6);
            [photoLocationView addSubview:photoRealView];
            
            // 小图标
            double iconSize = 20;
            YLImageView *iconImageView = [[YLImageView alloc]initWithFrame:CGRectMake(0, 0, iconSize, iconSize)];
            iconImageView.image = [UIImage imageNamed:@"placeholder3"];
            [photoRealView addSubview:iconImageView];
            iconImageView.center = [photoRealView convertPoint:photoRealView.center toView:photoRealView];
            
            // 边框
            YLImageView *photoBgImageView = [[YLImageView alloc]initWithFrame:CGRectMake(0, 0, photoRatioW, photoRatioH)];
            photoBgImageView.imageUrl = photo.image;
            [photoLocationView addSubview:photoBgImageView];
            
            double rotateAngle  = [photo.rotate doubleValue];
            double rotateRadian = rotateAngle / 180 * M_PI_2;
            photoLocationView.transform = CGAffineTransformMakeRotation(rotateRadian);
            
            // 点选按钮
            YLButton *button = [YLButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(0, 0, photoRatioW, photoRatioH);
            [photoLocationView addSubview:button];
            [button addTarget:self action:@selector(onPressSelectLoc:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

-(void)onPressSelectLoc:(YLButton*)button {
    // button.backgroundColor = COLORA(102,187,106,0.8);
    // 动画
    /*
    button.backgroundColor = [UIColor redColor];
    CABasicAnimation *an = [self opacityForeverAnimation:0.5];
    [button.layer addAnimation:an forKey:nil];
     */
    [self pushToPhotoManager:YES];
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
    self.index = 0;
    [self setupNavBarButtons];
    [self initTable];
    [self requestInitData];
    self.isExpand = YES;
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
        
        NSLog(@"%@",self.templateData.prodSn);
        [self.summaryTableView reloadData];
        self.workSpaceFrame = self.workSpaceView.frame;
        
        if (self.templateData.tmplData.count > 0) {
            TmplData *data = self.templateData.tmplData[0];
            Paper *paper = data.paper;
            self.selectPaper = paper;
            self.index = 0;
            [self calculateRatio];
            [self addCanvas];
            [self addBG];
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
    
    WEAK(self)
    cell.button.onPress = ^(YLButton *button) {
        STRONG(self)
        TmplData *data = self.templateData.tmplData[indexPath.row];
        Paper *paper = data.paper;
        self.selectPaper = paper;
        self.index = indexPath.row;
        [self calculateRatio];
        [self addCanvas];
        [self addBG];
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
    [self pushToPhotoManager:NO];
}



-(void)pushToPhotoManager:(BOOL)isPick {
    if (self.managerPhotoVC == nil) {
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.managerPhotoVC =  [story instantiateViewControllerWithIdentifier:@"ManagerPhotoViewController"];
        self.managerPhotoVC.isPick = isPick;
        [self.navigationController pushViewController:self.managerPhotoVC animated:YES];
        WEAK(self)
        self.managerPhotoVC.chooseOnePhoto = ^(PhotoCellData * _Nonnull data) {
            STRONG(self)
            NSLog(@"%@",data.data.imgUrl);
        };
    }
    else {
        self.managerPhotoVC.isPick = isPick;
        [self.navigationController pushViewController:self.managerPhotoVC animated:YES];
        WEAK(self)
        self.managerPhotoVC.chooseOnePhoto = ^(PhotoCellData * _Nonnull data) {
            STRONG(self)
            NSLog(@"%@",data.data.imgUrl);
        };
    }
  
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

@end
