//
//  ParticipantsCollectionViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImageView+Extension.h"
#import "UIStoryboardSegue+Extension.h"

#import "ChatManageTableViewController.h"

#import "ParticipantCollectionCell.h"
#import "ParticipantsManageTableViewController.h"

#import "ParticipantsCollectionViewController.h"

@interface ParticipantsCollectionViewController () {
    
    NSMutableArray *_participants;
}

@end

@implementation ParticipantsCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    
    [self reloadData];
}

- (void)reloadData {
    _participants = [[NSMutableArray alloc] init];
    
    if (MKMNetwork_IsCommunicator(_conversation.ID.type)) {
        // personal conversation
        [_participants addObject:_conversation.ID];
    } else if (MKMNetwork_IsGroup(_conversation.ID.type)) {
        // group conversation
        DIMGroup *group = DIMGroupWithID(_conversation.ID);
        [_participants addObjectsFromArray:group.members];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"addParticipantsSegue"]) {
        
        ParticipantsManageTableViewController *vc = [segue visibleDestinationViewController];
        vc.conversation = _conversation;
    }
    
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _participants.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell
    NSInteger count = _participants.count;
    NSInteger row = indexPath.row;
    if (row >= count) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:@"moreCell" forIndexPath:indexPath];
    }
    
    ParticipantCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"participantCollectionCell" forIndexPath:indexPath];
    cell.participant = [_participants objectAtIndex:row];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger count = _participants.count;
    NSInteger row = indexPath.row;
    if (row < count) {
        UICollectionViewCell *cell = [self collectionView:collectionView cellForItemAtIndexPath:indexPath];
        [_manageViewController performSegueWithIdentifier:@"profileSegue" sender:cell];
    }
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
