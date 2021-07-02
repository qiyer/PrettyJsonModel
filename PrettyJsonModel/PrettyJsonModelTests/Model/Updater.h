//
//  Updater.h
//  PrettyJsonModelTests
//
//  Created by qiye on 2021/7/2.
//

#import "PrettyJsonModel.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface Updater : PrettyJsonModel

@property (nonatomic, copy) NSString *desc;
@property (nonatomic)       BOOL      canSkip;
@property (nonatomic, copy) NSString *downloadUrl;
@property (nonatomic, copy) NSString *md5;
@property (nonatomic, copy) NSString *urlType;
@property (nonatomic, strong)  User  *updateUser;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, copy) NSString *country;

@end

NS_ASSUME_NONNULL_END
