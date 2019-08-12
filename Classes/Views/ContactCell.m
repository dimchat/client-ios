//
//  ContactCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"
#import "DIMProfile+Extension.h"

#import "User.h"

#import "ContactCell.h"

@implementation ContactCell

- (void)setContact:(DIMID *)contact {
    if (![_contact isEqual:contact]) {
        _contact = contact;
        
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // avatar
    CGRect frame = _avatarImageView.frame;
    UIImage *image = [DIMProfileForID(_contact) avatarImageWithSize:frame.size];
    if (!image) {
        image = [UIImage imageNamed:@"AppIcon"];
    }
    [_avatarImageView setImage:image];
    
    // name
    _nameLabel.text = user_title(_contact);
    
    // desc
    _descLabel.text = (NSString *)_contact;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    // avatar
    [_avatarImageView roundedCorner];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
