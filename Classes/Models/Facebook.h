//
//  Facebook.h
//  DIMClient
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSArray<DIMID *> ContactTable;

@interface Facebook : NSObject <DIMAccountDelegate,
                                DIMUserDataSource,
                                DIMUserDelegate,
                                //-
                                DIMGroupDataSource,
                                DIMGroupDelegate,
                                DIMMemberDelegate,
                                DIMChatroomDataSource,
                                //-
                                DIMEntityDataSource,
                                DIMProfileDataSource>

+ (instancetype)sharedInstance;

- (DIMID *)IDWithAddress:(const DIMAddress *)address;

- (void)addStation:(const DIMID *)stationID provider:(const DIMServiceProvider *)sp;

- (void)addContact:(const DIMID *)contactID user:(const DIMUser *)user;
- (void)removeContact:(const DIMID *)contactID user:(const DIMUser *)user;

- (ContactTable *)reloadContactsWithUser:(const DIMUser *)user;

- (void)setProfile:(DIMProfile *)profile forID:(const DIMID *)ID;

@end

NS_ASSUME_NONNULL_END
