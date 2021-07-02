//
//  PrettyJsonModel.h
//  PrettyJsonModel
//
//  Created by qiye on 2021/7/2.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PrettyJsonModelProtocol <NSObject>

@end

@interface PrettyJsonModel : NSObject<PrettyJsonModelProtocol>

//解析json字符串
- (void)parseJson:(NSString*) jsonStr;
//解析字典
- (void)parseDict:(NSDictionary*) jsonDict;

//标记NSArray包含Model对象
- (NSDictionary *)pjm_objectClassInArray;
//标记Model property 与 json key的映射关系
- (NSDictionary *)pjm_propertyNameMapToJsonKey;

+ (NSString *)checkPropertyName:(id) obj propertyName:(NSString *)name;
+ (NSDate *)checkNSDate:(id) obj propertyName:(NSString *)name timeStr:(NSString*) time;
@end

NS_ASSUME_NONNULL_END
