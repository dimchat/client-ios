//
//  ChatViewController.h
//  Sechat
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *messagesTableView;
@property (weak, nonatomic) IBOutlet UIView *trayView;
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;

@property (strong, nonatomic) DIMConversation *conversation;

- (IBAction)beginEditing:(id)sender;

- (IBAction)send:(id)sender;
- (IBAction)camera:(id)sender;
- (IBAction)album:(id)sender;

- (IBAction)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC;

@end

NS_ASSUME_NONNULL_END
