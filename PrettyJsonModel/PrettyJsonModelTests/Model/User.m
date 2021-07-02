//
//  User.m
//  PrettyJsonModelTests
//
//  Created by qiye on 2021/7/2.
//

#import "User.h"

@implementation User

- (NSDictionary *)pjm_objectClassInArray{
    return  @{@"petArr" : @"Pet"};
}

@end
