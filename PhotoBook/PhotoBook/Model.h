#import <Foundation/Foundation.h>
#import "AtomObject.h"
#import "RespObject.h"


#pragma mark -
#pragma mark 基类处理

@interface Response : RespObject

@property (nonatomic, assign) NSInteger status;

@end

#pragma mark -
#pragma mark 模板数据

// 图片偏移
@interface Offset : AtomObject
@property (nonatomic, copy) NSNumber *height;
@property (nonatomic, copy) NSNumber *width;
@property (nonatomic, copy) NSNumber *x;
@property (nonatomic, copy) NSNumber *y;

@end

// 图片源
@interface SourceImg : AtomObject
// 偏移量
@property (nonatomic, strong) Offset *offset;

// 上报数据：

/*
 "imgId": 1213,
 "imgSrc": "http:\/\/diy.h5.keepii.com\/uploads\/photo\/941in\/19\/02\/19\/thumb_11437514375c6b68d8e7ce46.92204605.jpeg",
 "rwidth": 562,
 "rheight": 750,
 "swidth": 562,
 "sheight": 375,
 "sx": 0,
 "sy": 188,
 "rotate": 0,
 */

@property (nonatomic, copy) NSString *imgSrc;// 图片缩略图

@property (nonatomic, copy) NSNumber *imgId;// 图片id - 用来标志原图


@property (nonatomic, copy) NSNumber *rwidth;  // 原图宽
@property (nonatomic, copy) NSNumber *rheight; // 原图高

// 剪切数据
@property (nonatomic, copy) NSNumber *swidth;
@property (nonatomic, copy) NSNumber *sheight;
@property (nonatomic, copy) NSNumber *sx;
@property (nonatomic, copy) NSNumber *sy;

// 旋转
@property (nonatomic, copy) NSNumber *rotate;


@end

// 背景
@interface Bg : AtomObject
@property (nonatomic, copy) NSNumber *height;
@property (nonatomic, copy) NSString *image;
@property (nonatomic, copy) NSNumber *width;
@property (nonatomic, copy) NSNumber *x;
@property (nonatomic, copy) NSNumber *y;
@property (nonatomic, copy) NSNumber *zIndex;
@end

// 相位
@interface Photos : AtomObject
@property (nonatomic, copy) NSNumber *height;
@property (nonatomic, copy) NSString *image;
@property (nonatomic) BOOL isDrag;
@property (nonatomic, copy) NSNumber *rotate;
@property (nonatomic, strong) SourceImg *sourceImg;
@property (nonatomic, copy) NSNumber *width;
@property (nonatomic, copy) NSNumber *x;
@property (nonatomic, copy) NSNumber *y;
@property (nonatomic, copy) NSNumber *zIndex;
@end


// 元素包裹
@interface Data : AtomObject
@property (nonatomic, strong) Bg *bg;
@property (nonatomic, copy) NSArray <Photos *> *photos;
@end

// 单页
@interface Page : AtomObject


@property (nonatomic, copy) NSNumber *height;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSNumber *width;
@property (nonatomic, copy) NSNumber *x;
@property (nonatomic, copy) NSNumber *y;
@property (nonatomic, copy) NSNumber *zIndex;
@property (nonatomic, strong) Data *data;

@end


// 单纸
@interface Paper : AtomObject

@property (nonatomic, copy) NSNumber *height;
@property (nonatomic, copy) NSNumber *width;

@property (nonatomic, copy) NSArray <Page *> *page;

// 缩略图（上传用）
@property (nonatomic, copy) NSString *previewImage;



@end



// 单纸包裹
@interface TmplData : AtomObject

@property (nonatomic, strong) Paper *paper;

@end


// 模版信息
@interface TemplateData : AtomObject

@property (nonatomic, copy)   NSArray <TmplData*> *tmplData;
@property (nonatomic, copy) NSString *platTag; // 平台标志
@property (nonatomic, copy) NSString *prodSn;  // 版型Sn

@end


#pragma mark -
#pragma mark 模板返回接口

@interface TemplateResponse : Response

@property (nonatomic, copy)   TemplateData *data;

@end

#pragma mark -
#pragma mark 模板返回接口

@interface PKPhoto : AtomObject

@property (nonatomic, copy) NSNumber *imgId;
@property (nonatomic, copy) NSNumber *imgSize;
@property (nonatomic, copy) NSString *imgUrl;
@property (nonatomic, copy) NSNumber *thumbImgHeight;
@property (nonatomic, copy) NSString *thumbImgUrl;
@property (nonatomic, copy) NSNumber *thumbImgWidth;

@end

@interface PKPhotoResponse : Response
@property (nonatomic, copy)   PKPhoto *data;
@end


@interface PhotoCellData : NSObject

@property (nonatomic, copy)   PKPhoto *data;
@property (nonatomic, copy)   UIImage *image;

@end








