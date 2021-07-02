//
//  PrettyJsonModel.m
//  PrettyJsonModel
//
//  Created by qiye on 2021/7/2.
//

#import "PrettyJsonModel.h"
#import <objc/runtime.h>

static const char PJMObjcModelPropertyKey = '\0';
static const char PJMObjcDatePropertyKey  = '\0';

static dispatch_semaphore_t pjm_modelSemaphore;
static dispatch_once_t      pjm_modelOnceToken;

@implementation PrettyJsonModel


-(void)setValue:(id)value forUndefinedKey:(NSString *)key{
    NSLog(@"[%@] parse undefinedKey:%@ ",NSStringFromClass([self class]), key);
}

- (void)parseJson:(NSString*) jsonStr{
    NSError *jsonError;
    NSData *objectData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:objectData
                                          options:NSJSONReadingMutableContainers
                                            error:&jsonError];
    if (jsonError) {
        NSLog(@"[%@] json to Dictionary error:%@ ",NSStringFromClass([self class]), jsonError);
        return;
    }
    [self parseDict:jsonDict];
}

- (void)parseDict:(NSDictionary*) jsonDict{
    if (!jsonDict) {
        NSLog(@"[%@] dictionary is null. ",NSStringFromClass([self class]));
        return;
    }
    __block NSDictionary * orginDict = jsonDict;
        
    @try {
        if([self pjm_propertyNameMapToJsonKey]){
            [[self pjm_propertyNameMapToJsonKey] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([jsonDict.allKeys containsObject:obj]) {
                    NSMutableDictionary * cloneDic = [NSMutableDictionary dictionaryWithDictionary:jsonDict];
                    [cloneDic setObject:[jsonDict objectForKey:obj] forKey:key];
                    orginDict = cloneDic;
                }
            }];
        }

        [self setValuesForKeysWithDictionary:orginDict];
        [self parseChildDict:jsonDict];
    } @catch (NSException *exception) {
        NSLog(@"[%@] parseDict: with error:%@ ",NSStringFromClass([self class]), exception);
    } @finally {
        
    }
}

-(void)parseChildDict:(NSDictionary*) jsonDict{
    [jsonDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[NSDictionary class]]){
            NSString * typeClass = [PrettyJsonModel checkPropertyName:self propertyName:key];
            if (typeClass == nil) return;
            Class _class = NSClassFromString(typeClass);
            if (!_class || [_class isMemberOfClass:[NSDictionary class]] || [_class isMemberOfClass:[NSMutableDictionary class]]) {
                return;
            }
            id value = [_class new];
            if([value respondsToSelector:@selector(parseDict:)]){
                [value parseDict:obj];
                [self setValue:value forKey:key];
                [self parseChildDict:obj];
            }
        }
        else if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSMutableArray class]]) {
            NSDictionary * mapper = [self pjm_objectClassInArray];
            if(mapper == nil) return;
            __block NSString * propertyName = key;
            [[self pjm_propertyNameMapToJsonKey] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull _key, id  _Nonnull _obj, BOOL * _Nonnull _stop) {
                if ([key isEqualToString:obj]) {
                    propertyName = _key;
                    *_stop = YES;
                }
            }];
            NSString * typeClass = [mapper objectForKey:propertyName];
            if (mapper == nil || typeClass == nil) return;
            Class _class = NSClassFromString(typeClass);
            if (!_class || ![_class conformsToProtocol:@protocol(PrettyJsonModelProtocol)] ) {
                NSLog(@"[%@] pjm_objectClassInArray: %@ is wrong. ",NSStringFromClass([self class]) ,typeClass);
                return;
            }
            NSArray * arr = (NSArray *)obj;
            __block NSMutableArray * parseArr = [NSMutableArray array];
            [arr enumerateObjectsUsingBlock:^(id  _Nonnull _obj, NSUInteger _idx, BOOL * _Nonnull _stop) {
                id value = [_class new];
                if([value respondsToSelector:@selector(parseDict:)]){
                    [value parseDict:_obj];
                    [self parseChildDict:_obj];
                    [parseArr addObject:value];
                }
            }];
            [self setValue:parseArr forKey:key];
        }
        else {
            NSDate* date = [PrettyJsonModel checkNSDate:self propertyName:key timeStr:obj];
            if (date)
                [self setValue:date forKey:key];
        }
        // check keyPath
        [[self pjm_getKeyPathDict] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull _key, id  _Nonnull _obj, BOOL * _Nonnull _stop) {
            NSArray * keyPaths = _obj;
            id temp = jsonDict;
            for (int i = 0; i<keyPaths.count; i++) {
                if (temp == nil) {
                    break;
                }
                NSString * keyPath = keyPaths[i];
                temp = [temp objectForKey:keyPath];
            }
            if (temp != nil) {
                NSDate* date = [PrettyJsonModel checkNSDate:self propertyName:_key timeStr:temp];
                if (date)
                    [self setValue:date forKey:_key];
                else
                    [self setValue:temp forKey:_key];
            }
        }];
    }];
}

- (NSDictionary *)pjm_objectClassInArray
{
    //return  @{@"users" : @"User"};
    return nil;
}

- (NSDictionary *)pjm_propertyNameMapToJsonKey
{
    //return @{@"desc" : @"desciption"};
    return nil;
}

-(NSDictionary *)pjm_getKeyPathDict{
    static NSMutableDictionary * dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [NSMutableDictionary dictionary];
        [[self pjm_propertyNameMapToJsonKey] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj  && [obj containsString:@"."]) {
                NSArray * arr = [obj componentsSeparatedByString:@"."];
                [dict setObject:arr forKey:key];
            }
        }];
    });
    return dict;
}

+ (NSString*)checkPropertyName:(id) obj propertyName:(NSString *)name {
    
    NSDictionary * dict = [self getObjcModelProperty:obj key:&PJMObjcModelPropertyKey];
    NSString* propertyType = [dict objectForKey:name]?:nil;
    return propertyType;
}

+ (NSDate *)checkNSDate:(id) obj propertyName:(NSString *)name timeStr:(NSString*) time {
    
    NSDictionary * dict = [self getObjcModelProperty:obj key:&PJMObjcDatePropertyKey];
    if ([dict objectForKey:name]) {
        return PJMNSDateFromString(time);
    }
    return nil;
}

+ (NSDictionary*)getObjcModelProperty:(id) obj key:(const void *)key{
    dispatch_once(&pjm_modelOnceToken, ^{
        pjm_modelSemaphore = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(pjm_modelSemaphore, DISPATCH_TIME_FOREVER);
    NSMutableDictionary *modelCachedInfo  = [self pjm_propertyDictForKey:key];
    NSMutableDictionary *dateCachedInfo   = [self pjm_propertyDictForKey:key];
    NSMutableDictionary *cachedProperties = modelCachedInfo[NSStringFromClass([obj class])];
    NSMutableDictionary *dateProperties   = dateCachedInfo[NSStringFromClass([obj class])];
    if (!cachedProperties || !dateProperties) {
        if(!cachedProperties) cachedProperties = [NSMutableDictionary dictionary];
        if(!dateProperties)   dateProperties   = [NSMutableDictionary dictionary];
        unsigned int propertyCount;
        objc_property_t* properties = class_copyPropertyList([obj class], &propertyCount);
        for(int i=0;i<propertyCount;i++){
            objc_property_t property = properties[i];
            const char* propertyName = property_getName(property);
            NSString* propertyNameStr = [NSString stringWithUTF8String:propertyName];

            char* typeEncoding = property_copyAttributeValue(property,"T");
            NSString* typeEncodingStr = [NSString stringWithUTF8String:typeEncoding];
            typeEncodingStr = [typeEncodingStr stringByReplacingOccurrencesOfString:@"@" withString:@""];
            typeEncodingStr = [typeEncodingStr stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            Class _class = NSClassFromString(typeEncodingStr);
            if (_class && [_class conformsToProtocol:@protocol(PrettyJsonModelProtocol)]) {
                [cachedProperties setObject:typeEncodingStr forKey:propertyNameStr];
            }
            else if (_class && [_class isSubclassOfClass:[NSDate class]] ) {
                [dateProperties setObject:typeEncodingStr forKey:propertyNameStr];
            }
        }
        free(properties);
    }
    dispatch_semaphore_signal(pjm_modelSemaphore);
    if (key == &PJMObjcModelPropertyKey) return cachedProperties;
    if (key == &PJMObjcDatePropertyKey)  return dateProperties;
    return nil;
}

+ (NSMutableDictionary *)pjm_propertyDictForKey:(const void *)key
{
    static NSMutableDictionary *objcModelPropertyDict;
    static NSMutableDictionary *objcDatePropertyDict;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        objcModelPropertyDict = [NSMutableDictionary dictionary];
        objcDatePropertyDict  = [NSMutableDictionary dictionary];
    });
    
    if (key == &PJMObjcModelPropertyKey) return objcModelPropertyDict;
    if (key == &PJMObjcDatePropertyKey)  return objcDatePropertyDict;
    return nil;
}

// This function copies from `YYModel`. Thank you for the "YY Kinger".
/// Parse string to date.
static NSDate *PJMNSDateFromString(NSString *string) {
    typedef NSDate* (^PJMNSDateParseBlock)(NSString *string);
    #define kParserNum 34
    static PJMNSDateParseBlock blocks[kParserNum + 1] = {0};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            /*
             2014-01-20  // Google
             */
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter.dateFormat = @"yyyy-MM-dd";
            blocks[10] = ^(NSString *string) { return [formatter dateFromString:string]; };
        }
        
        {
            /*
             2014-01-20 12:24:48
             2014-01-20T12:24:48   // Google
             2014-01-20 12:24:48.000
             2014-01-20T12:24:48.000
             */
            NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter1.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
            
            NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter2.dateFormat = @"yyyy-MM-dd HH:mm:ss";

            NSDateFormatter *formatter3 = [[NSDateFormatter alloc] init];
            formatter3.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter3.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter3.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";

            NSDateFormatter *formatter4 = [[NSDateFormatter alloc] init];
            formatter4.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter4.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter4.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
            
            blocks[19] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter1 dateFromString:string];
                } else {
                    return [formatter2 dateFromString:string];
                }
            };

            blocks[23] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter3 dateFromString:string];
                } else {
                    return [formatter4 dateFromString:string];
                }
            };
        }
        
        {
            /*
             2014-01-20T12:24:48Z        // Github, Apple
             2014-01-20T12:24:48+0800    // Facebook
             2014-01-20T12:24:48+12:00   // Google
             2014-01-20T12:24:48.000Z
             2014-01-20T12:24:48.000+0800
             2014-01-20T12:24:48.000+12:00
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";

            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";

            blocks[20] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[24] = ^(NSString *string) { return [formatter dateFromString:string]?: [formatter2 dateFromString:string]; };
            blocks[25] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[28] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
            blocks[29] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
        
        {
            /*
             Fri Sep 04 00:12:21 +0800 2015 // Weibo, Twitter
             Fri Sep 04 00:12:21.000 +0800 2015
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"EEE MMM dd HH:mm:ss Z yyyy";

            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"EEE MMM dd HH:mm:ss.SSS Z yyyy";

            blocks[30] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[34] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
    });
    if (!string) return nil;
    if (string.length > kParserNum) return nil;
    PJMNSDateParseBlock parser = blocks[string.length];
    if (!parser) return nil;
    return parser(string);
    #undef kParserNum
}

@end

