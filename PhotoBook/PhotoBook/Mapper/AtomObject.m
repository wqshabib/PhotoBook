#import "AtomObject.h"

static void *kCachePropertyKey = &kCachePropertyKey;

@interface AtomObject () <JSONSerializing>

@end

@implementation AtomObject

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        NSArray *propertyNames = [[self class] p_propertyKeys].allObjects;
        for (NSString *propertyName in propertyNames) {
            [self setValue:[coder decodeObjectForKey:propertyName] forKey:propertyName];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    NSArray *propertyNames = [[self class] p_propertyKeys].allObjects;
    for (NSString *propertyName in propertyNames) {
        id propertyValue = [self valueForKey:propertyName];
        [aCoder encodeObject:propertyValue forKey:propertyName];
    }
}

#pragma mark - NSCoping

- (id)copyWithZone:(NSZone *)zone {
    AtomObject *result = [[[self class] allocWithZone:zone] init];
    NSArray *propertyNames = [[self class] p_propertyKeys].allObjects;
    for (NSString *propertyName in propertyNames) {
        id propertyValue = [self valueForKey:propertyName];
        if ([propertyValue respondsToSelector:@selector(copyWithZone:)]) {
            propertyValue = [propertyValue copyWithZone:zone];
        }
        [result setValue:propertyValue forKey:propertyName];
    }
    return result;
}

#pragma mark - Public

+ (NSDictionary *)bridgePropertyAndJSON {
    
    return nil;
}

+ (NSDictionary *)bridgeClassAndArray {
    
    return nil;
}

#pragma mark - YHJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    NSArray *propertyKeys = [[self class] p_propertyKeys].allObjects;
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjects:propertyKeys forKeys:propertyKeys];
    NSDictionary *changeJSONKey = [self bridgePropertyAndJSON];
    if (changeJSONKey) {
        [dic setValuesForKeysWithDictionary:changeJSONKey];
    }
    return dic;
}

+ (NSDictionary *)convertClassStringDictionary {
    
    return [self bridgeClassAndArray];
}

#pragma mark - Private

+ (NSSet *)p_propertyKeys {
    
    NSSet *cachedKeys = objc_getAssociatedObject(self, kCachePropertyKey);
    if (cachedKeys != nil) return cachedKeys;
    
    NSMutableSet *keys = [NSMutableSet set];
    unsigned int propertyCount = 0;
    objc_property_t *propertyList = class_copyPropertyList([self class], &propertyCount);
    for (int i=0; i<propertyCount; i++) {
        objc_property_t *property = propertyList + i;
        NSString *propertyName = [NSString stringWithCString:property_getName(*property) encoding:NSUTF8StringEncoding];
        [keys addObject:propertyName];
    }
    free(propertyList);
    objc_setAssociatedObject(self, kCachePropertyKey, keys, OBJC_ASSOCIATION_COPY);
    
    return keys;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, [JsonAdapter jsonStringFromObject:self]];
}

#pragma mark - 归档

+ (__kindof AtomObject *_Nonnull)loadCache{
    @try {
        AtomObject *object = [[[self class] alloc] init];
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:[object archiverPath]];
        return object;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

- (BOOL)saveCache {
    
    @try {
        [NSKeyedArchiver archiveRootObject:self toFile:[self archiverPath]];
        return YES;
    }
    @catch (NSException *exception) {
        return NO;
    }
}

+ (BOOL)clearCache {
    return [[NSFileManager defaultManager] removeItemAtPath:[self archiverPath] error:nil];
}

+ (NSString *)archiverPath{
    NSString *folderName =[NSString stringWithFormat:@"Archiver"];
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *optionPath = [documentPath stringByAppendingPathComponent:folderName];
    if (![fm fileExistsAtPath:optionPath]) {
        [fm createDirectoryAtPath:optionPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [NSString stringWithFormat:@"%@/%@", optionPath,[[self class] description]];
}

- (NSString *)archiverPath{
    NSString *folderName =[NSString stringWithFormat:@"Archiver"];
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *optionPath = [documentPath stringByAppendingPathComponent:folderName];
    if (![fm fileExistsAtPath:optionPath]) {
        [fm createDirectoryAtPath:optionPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [NSString stringWithFormat:@"%@/%@", optionPath,[[self class] description]];
}

- (NSString *_Nullable)toJson
{
    return [JsonAdapter jsonStringFromObject:self];
}

- (NSDictionary*)toDict
{
    return [JsonAdapter jsonDictionaryFromObject:self];
}

+(NSString*)round:(NSString*)price {
    if (price == nil) {
        return @"0";
    }
    NSDecimalNumber *numPrice = [[NSDecimalNumber alloc]initWithString:price];
    NSDecimalNumberHandler* handle = [NSDecimalNumberHandler
                                      decimalNumberHandlerWithRoundingMode:NSRoundBankers
                                      scale:2
                                      raiseOnExactness:NO
                                      raiseOnOverflow:NO
                                      raiseOnUnderflow:NO
                                      raiseOnDivideByZero:NO];
    NSDecimalNumber *res = [numPrice decimalNumberByRoundingAccordingToBehavior:handle];
    // return [NSString stringWithFormat:@"%@",res];
    

    // 格式化成分
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.roundingMode = NSNumberFormatterRoundFloor;
    formatter.maximumFractionDigits = 2;
    formatter.minimumFractionDigits = 2;
    formatter.minimumIntegerDigits  = 1;
    NSString *res00 = [formatter stringFromNumber:res];
    return res00;
}

@end
