//
//  Model.m
//  PhotoBook
//
//  Created by sino on 2019/2/22.
//  Copyright © 2019 sino. All rights reserved.
//

#import "Model.h"

@implementation Response

@end

@implementation Offset

@end

@implementation SourceImg

@end

@implementation Bg

@end

@implementation Photos
@end

@implementation Data
+ (NSDictionary *)bridgeClassAndArray {
    return @{@"photos":@"Photos"};
}
@end

@implementation Page
@end

@implementation Paper

+ (NSDictionary *)bridgeClassAndArray {
    return @{@"page":@"Page"};
}

@end

@implementation TmplData

@end

@implementation TemplateData
+ (NSDictionary *)bridgeClassAndArray {
    return @{@"tmplData":@"TmplData"};
}
@end

@implementation TemplateResponse

@end

@implementation PKPhotoResponse

@end

@implementation PKPhoto

@end

@implementation PhotoCellData

@end

@implementation GenerateData
+ (NSDictionary *)bridgeClassAndArray {
    return @{@"prodData":@"TmplData"};
}
@end

@implementation GenerateResponse

@end

