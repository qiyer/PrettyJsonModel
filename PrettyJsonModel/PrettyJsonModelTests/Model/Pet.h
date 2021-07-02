//
//  Pet.h
//  PrettyJsonModelTests
//
//  Created by qiye on 2021/7/2.
//

#import "PrettyJsonModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface Pet : PrettyJsonModel

@property (nonatomic,  copy)  NSString * petName;
@property (nonatomic, assign) NSUInteger petAge;

@end

NS_ASSUME_NONNULL_END
