//
//  PrettyJsonModelTests.m
//  PrettyJsonModelTests
//
//  Created by qiye on 2021/7/2.
//

#import <XCTest/XCTest.h>
#import "Updater.h"

@interface PrettyJsonModelTests : XCTestCase

@end

@implementation PrettyJsonModelTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    NSDictionary * updaterDic1 = @{@"downloadUrl":@"https://www.baidu.com",
                                   @"urlType":@"test",
                                   @"md5":@"af687afa6sdfasdfads78adsfs",
                                   @"canSkip":@1,
                                   @"description":@"description test",
                                   @"language":@"en",
                                   @"endTime":@"2021-07-02 11:06:05",
                                   @"region":@{@"country":@"china", @"lang":@"ch", @"time":@"2021-07-02 14:00:05"},
                                   };
    // have more key-values
    NSDictionary * updaterDic2 = @{@"downloadUrl":@"https://www.baidu.com",
                                   @"urlType":@"test",
                                   @"md5":@"af687afa6sdfasdfads78adsfs",
                                   @"canSkip":@1,
                                   @"description":@"description test",
                                   @"testkey1":@"test value1",
                                   @"testkey2":@"test value2",
                                   @"updateUser":@{@"userName":@"jobs",
                                                   @"userAge":@46,
                                                   @"userPet":@{@"petName":@"cat"  , @"petAge":@3},
                                                   @"petArr":@[@{@"petName":@"dog" , @"petAge":@9},
                                                               @{@"petName":@"brid", @"petAge":@2}
                                                   ]
                                                }
                                   };
    // have less key-values
    NSDictionary * updaterDic3 = @{@"downloadUrl":@"https://www.baidu.com",
                                   @"urlType":@"test",
                                   @"canSkip":@1
                                   };
    
    NSLog(@"################################################");
    Updater * updater1 = [Updater new];
    [updater1 parseJson:[self dataToJsonString:updaterDic1]];
    NSLog(@"updater1->downloadUrl:%@, updater1->desc:%@, updater1->language:%@, updater1->endTime:%@",updater1.downloadUrl, updater1.desc, updater1.language, updater1.endTime);
        
    Updater * updater3 = [Updater new];
    [updater3 parseJson:[self dataToJsonString:updaterDic3]];
    NSLog(@"updater3->downloadUrl:%@, updater3->desc:%@",updater3.downloadUrl, updater3.desc);
    
    Updater * updater4 = [Updater new];
    [updater4 parseDict:updaterDic2];
    NSLog(@"updater4->downloadUrl:%@, updater4->updateUser->userName:%@",updater4.downloadUrl, updater4.updateUser.userPet.petName);
    
    NSLog(@"################################################");

}

-(NSString*)dataToJsonString:(id)object
{
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    NSDictionary * updaterDic = @{@"downloadUrl":@"https://www.baidu.com",
                                   @"urlType":@"test",
                                   @"md5":@"af687afa6sdfasdfads78adsfs",
                                   @"canSkip":@1,
                                   @"description":@"description test",
                                   @"testkey1":@"test value1",
                                   @"testkey2":@"test value2",
                                   @"updateUser":@{@"userName":@"jobs",
                                                   @"userAge":@46,
                                                   @"userPet":@{@"petName":@"cat"  , @"petAge":@3},
                                                   @"petArr":@[@{@"petName":@"dog" , @"petAge":@9},
                                                               @{@"petName":@"brid", @"petAge":@2}
                                                   ]
                                                }
                                   };
    [self measureBlock:^{
        for(int i = 0;i<10000;i++){
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                Updater * updater = [Updater new];
                [updater parseJson:[self dataToJsonString:updaterDic]];
                NSLog(@"updater->downloadUrl:%@, updater->desc:%@",updater.downloadUrl, updater.desc);
            });
        }
    }];
}

@end
