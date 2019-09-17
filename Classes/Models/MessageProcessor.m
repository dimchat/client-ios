//
//  MessageProcessor.m
//  DIMClient
//
//  Created by Albert Moky on 2018/11/15.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSObject+JsON.h"
#import "NSNotificationCenter+Extension.h"

#import "User.h"
#import "Client.h"
#import "AccountDatabase.h"

#import "MessageProcessor.h"

typedef NSMutableArray<DIMConversation *> ConversationListM;

@interface MessageProcessor () {
    
    ConversationListM *_conversationList;
}

@end

@implementation MessageProcessor

SingletonImplementations(MessageProcessor, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        
        DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
        clerk.conversationDataSource = self;
        clerk.conversationDelegate = self;
    }
    return self;
}

- (void)sortConversationList {
    /*
     These constants are used to indicate how items in a request are ordered,
     from the first one given in a method invocation or function call
     to the last (that is, left to right in code).
     
     Given the function:
     NSComparisonResult f(int a, int b)
     
     If:
     a < b   then return NSOrderedAscending.
     a > b   then return NSOrderedDescending.
     a == b  then return NSOrderedSame.
     */
    NSComparator comparator = ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        DIMInstantMessage *msg1 = [obj1 lastMessage];
        DIMInstantMessage *msg2 = [obj2 lastMessage];
        NSNumber *time1 = [msg1 objectForKey:@"time"];
        NSNumber *time2 = [msg2 objectForKey:@"time"];
        NSTimeInterval t1 = [time1 doubleValue];
        NSTimeInterval t2 = [time2 doubleValue];
        if (t1 < t2) {
            return NSOrderedDescending;
        } else if (t1 > t2) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    };
    // sort all conversations
    NSArray *array = [self allConversations];
    NSMutableArray *mArray = [array mutableCopy];
    [mArray sortUsingComparator:comparator];
    _conversationList = mArray;
}

- (NSInteger)numberOfConversations {
    if (!_conversationList) {
        [self sortConversationList];
    }
    return [_conversationList count];
}

- (DIMConversation *)conversationAtIndex:(NSInteger)index {
    return [_conversationList objectAtIndex:index];
}

- (BOOL)removeConversationAtIndex:(NSInteger)index {
    DIMConversation *chatBox = [self conversationAtIndex:index];
    return [self removeConversation:chatBox];
}

- (BOOL)removeConversation:(DIMConversation *)chatBox {
    BOOL removed = [super removeConversation:chatBox];
    if (removed) {
        [_conversationList removeObject:chatBox];
        NSLog(@"conversation removed: %@", chatBox.ID);
        [NSNotificationCenter postNotificationName:kNotificationName_MessageCleaned
                                            object:self
                                          userInfo:@{@"ID": chatBox.ID}];
    }
    return removed;
}

- (BOOL)clearConversationAtIndex:(NSInteger)index {
    DIMConversation *chatBox = [self conversationAtIndex:index];
    return [self clearConversation:chatBox];
}

- (BOOL)clearConversation:(DIMConversation *)chatBox {
    BOOL cleared = [super clearConversation:chatBox];
    if (cleared) {
        NSLog(@"conversation cleaned: %@", chatBox.ID);
        [NSNotificationCenter postNotificationName:kNotificationName_MessageCleaned
                                            object:self
                                          userInfo:@{@"ID": chatBox.ID}];
    }
    return cleared;
}

#pragma mark DIMConversationDelegate

// save the new message to local storage
- (BOOL)conversation:(DIMConversation *)chatBox insertMessage:(DIMInstantMessage *)iMsg {
    if (![super conversation:chatBox insertMessage:iMsg]) {
        NSLog(@"failed to save message: %@", iMsg);
        return NO;
    }
    // sort conversation list
    [self sortConversationList];
    
    // check whether the group members info needs update
    DIMID *ID = chatBox.ID;
    if (MKMNetwork_IsGroup(ID.type)) {
        DIMGroup *group = DIMGroupWithID(ID);
        DIMContent *content = iMsg.content;
        // if the group info not found, and this is not an 'invite' command
        //     query group info from the sender
        BOOL needsUpdate = group.founder == nil;
        if (content.type == DKDContentType_History) {
            NSString *command = [(DIMGroupCommand *)content command];
            if ([command isEqualToString:DIMGroupCommand_Invite]) {
                // FIXME: can we trust this stranger?
                //        may be we should keep this members list temporary,
                //        and send 'query' to the founder immediately.
                // TODO: check whether the members list is a full list,
                //       it should contain the group owner(founder)
                needsUpdate = NO;
            }
        }
        if (needsUpdate) {
            DIMID *sender = DIMIDWithString(iMsg.envelope.sender);
            NSAssert(sender != nil, @"sender error: %@", iMsg);
            
            DIMQueryGroupCommand *query;
            query = [[DIMQueryGroupCommand alloc] initWithGroup:ID];
            
            Client *client = [Client sharedInstance];
            [client sendContent:query to:sender];
        }
    }
    
    [NSNotificationCenter postNotificationName:kNotificationName_MessageUpdated
                                        object:self
                                      userInfo:@{@"ID": ID}];
    return YES;
}

@end

#pragma mark -

NSString * const kNotificationName_GroupMembersUpdated = @"GroupMembersUpdated";

@implementation MessageProcessor (GroupCommand)

- (BOOL)processQueryCommand:(DIMGroupCommand *)gCmd
                  commander:(DIMID *)sender
                  polylogue:(DIMPolylogue *)group {
    if (![super processQueryCommand:gCmd commander:sender polylogue:group]) {
        // command error
        return NO;
    }
    
    NSArray *members = group.members;
    
    // pack command and send out
    DIMInviteCommand *invite;
    invite = [[DIMInviteCommand alloc] initWithGroup:group.ID members:members];
    Client *client = [Client sharedInstance];
    [client sendContent:invite to:sender];
    
    return YES;
}

- (BOOL)processGroupCommand:(DIMGroupCommand *)gCmd
                  commander:(DIMID *)sender {
    BOOL OK = [super processGroupCommand:gCmd commander:sender];
    
    if (OK) {
        // notice
        DIMID *groupID = DIMIDWithString(gCmd.group);
        NSString *name = kNotificationName_GroupMembersUpdated;
        NSDictionary *info = @{@"group": groupID};
        [NSNotificationCenter postNotificationName:name
                                            object:self
                                          userInfo:info];
    }
    return OK;
}

@end
