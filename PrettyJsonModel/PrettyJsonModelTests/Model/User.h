//
//  User.h
//  PrettyJsonModelTests
//
//  Created by qiye on 2021/7/2.
//

#import "PrettyJsonModel.h"
#import "Pet.h"

NS_ASSUME_NONNULL_BEGIN

@interface User : PrettyJsonModel

@property (nonatomic,  copy)  NSString      * userName;
@property (nonatomic, assign) NSUInteger      userAge;
@property (nonatomic, strong) Pet           * userPet;
@property (nonatomic, strong) NSArray<Pet*> * petArr;

@end

NS_ASSUME_NONNULL_END
