//
//  Updater.m
//  PrettyJsonModelTests
//
//  Created by qiye on 2021/7/2.
//

#import "Updater.h"

@implementation Updater

- (NSDictionary *)pjm_propertyNameMapToJsonKey
{
    return @{@"desc"    : @"description",
             @"language": @"lang",
             @"country" :@"region.country"
    };
}

@end
