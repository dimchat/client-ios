//
//  MsgCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSString+Extension.h"
#import "UIImage+Extension.h"
#import "UIImageView+Extension.h"
#import "UIButton+Extension.h"
#import "UIView+Extension.h"
#import "UIStoryboard+Extension.h"
#import "DIMProfile+Extension.h"
#import "DIMInstantMessage+Extension.h"
#import "WebViewController.h"
#import "User.h"
#import "MessageDatabase.h"
#import "ZoomInViewController.h"
#import "SentMessageCell.h"

@interface SentMessageCell ()

@property (strong, nonatomic) UIImage *picture;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGuesture;

@end

@implementation SentMessageCell

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)iMsg bounds:(CGRect)rect {
    NSString *text = nil;
    if (iMsg.content.type == DKDContentType_Text) {
        text = [(DIMTextContent *)iMsg.content text];
    }
    
    CGFloat cellWidth = rect.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    CGSize size;
    
    UIImage *image = iMsg.image;
    if (image) {
        size = [UIScreen mainScreen].bounds.size;
        CGFloat max_width = MIN(size.width, size.height) * 0.382;
        if (image.size.width > max_width) {
            CGFloat ratio = max_width / image.size.width;
            size = CGSizeMake(image.size.width * ratio, image.size.height * ratio);
        } else {
            size = image.size;
        }
    } else {
        UIFont *font = [UIFont systemFontOfSize:16];
        size = CGSizeMake(msgWidth - edges.left - edges.right, MAXFLOAT);
        size = [text sizeWithFont:font maxSize:size];
    }
    
    CGFloat cellHeight = size.height + edges.top + edges.bottom + 16;
    
    if (cellHeight < 55) {
        cellHeight = 55;
    }
    return CGSizeMake(cellWidth, cellHeight);
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.avatarImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:self.avatarImageView];
        
        UIImage *chatBackgroundImage = [UIImage imageNamed:@"sender_bubble"];
        UIEdgeInsets insets = UIEdgeInsetsMake(17.0, 20.0, 17.0, 28.0);
        self.messageImageView = [[UIImageView alloc] initWithImage:[chatBackgroundImage resizableImageWithCapInsets:insets]];
        [self.contentView addSubview:self.messageImageView];
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.numberOfLines = -1;
        self.messageLabel.textColor = [UIColor whiteColor];
        self.messageLabel.font = [UIFont systemFontOfSize:16.0];
        [self.contentView addSubview:self.messageLabel];
        
        self.picImageView = [[UIImageView alloc] init];
        self.picImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.picImageView];
        
        self.infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.contentView addSubview:self.infoButton];
        
        self.longPressGuesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressHappen:)];
        [self.contentView addGestureRecognizer:self.longPressGuesture];
    }
    
    return self;
}

- (UIImage *)picture {
    if (!_picture) {
        _picture = self.msg.image;
    }
    return _picture;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat height = 44.0;
    CGFloat width = 44.0;
    CGFloat y = 8.0;
    CGFloat x = self.contentView.bounds.size.width - 8.0 - width;
    
    self.avatarImageView.frame = CGRectMake(x, y, width, height);
    self.avatarImageView.layer.cornerRadius = width / 2.0;
    self.avatarImageView.layer.masksToBounds = YES;
    
    CGFloat messageMaxWidth = self.contentView.bounds.size.width * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    
    // message
    UIFont *font = self.messageLabel.font;
    NSString *text = self.messageLabel.text;
    CGSize contentSize;
    
    if (_picture) {
        
        self.messageImageView.hidden = YES;
        self.messageLabel.hidden = YES;
        self.picImageView.hidden = NO;
        
        contentSize = [UIScreen mainScreen].bounds.size;
        CGFloat max_width = MIN(contentSize.width, contentSize.height) * 0.382;
        if (_picture.size.width > max_width) {
            CGFloat ratio = max_width / _picture.size.width;
            contentSize = CGSizeMake(_picture.size.width * ratio, _picture.size.height * ratio);
        } else {
            contentSize = _picture.size;
        }
        
        //Show Image
        x = self.avatarImageView.frame.origin.x - 10.0 - contentSize.width;
        y = self.avatarImageView.frame.origin.y + 5.0;
        width = contentSize.width;
        height = contentSize.height;
        self.picImageView.frame = CGRectMake(x, y, width, height);
        
    } else {
        
        self.messageImageView.hidden = NO;
        self.messageLabel.hidden = NO;
        self.picImageView.hidden = YES;
        
        contentSize = CGSizeMake(messageMaxWidth - edges.left - edges.right, MAXFLOAT);
        contentSize = [text sizeWithFont:font maxSize:contentSize];
        
        CGSize imageSize = CGSizeMake(contentSize.width + edges.left + edges.right,
                                      contentSize.height + edges.top + edges.bottom);
        x = self.avatarImageView.frame.origin.x - 10.0 - imageSize.width;
        y = self.avatarImageView.frame.origin.y + 3.0;
        width = imageSize.width;
        height = imageSize.height;
        self.messageImageView.frame = CGRectMake(x, y, width, height);
        
        x = x + edges.left - 5.0;
        y = y + edges.top;
        width = contentSize.width;
        height = contentSize.height;
        self.messageLabel.frame = CGRectMake(x, y, width, height);
    }
}

- (void)setMsg:(DIMInstantMessage *)msg {
    if (![_msg isEqual:msg]) {
        _msg = msg;
        
        self.picture = msg.image;
        
        id cell = self;
        UIImageView *avatarImageView = [cell avatarImageView];
        UILabel *messageLabel = [cell messageLabel];
        
        DIMEnvelope *env = msg.envelope;
        DIMID *sender = DIMIDWithString(env.sender);
        DIMContent *content = msg.content;
        DIMProfile *profile = DIMProfileForID(sender);
        
        // avatar
        CGRect avatarFrame = avatarImageView.frame;
        UIImage *image = [profile avatarImageWithSize:avatarFrame.size];
        [avatarImageView setImage:image];
        
        // message
        switch (msg.content.type) {
            case DKDContentType_Text: {
                // show text
                messageLabel.text = [content messageText];
                // double click to zoom in
                [messageLabel addDoubleClickTarget:self action:@selector(zoomIn:)];
            }
            break;
                
            case DKDContentType_File: {
                // TODO: show file info
                messageLabel.text = [content messageText];
            }
            break;
                
            case DKDContentType_Image: {
                // show image
                if (_picture) {
                    self.picImageView.image = _picture;
                } else {
                    messageLabel.text = [content messageText];
                }
                
                [self.picImageView addClickTarget:self action:@selector(zoomIn:)];
            }
            break;
                
            case DKDContentType_Audio: {
                // TODO: show audio info
                messageLabel.text = [content messageText];
            }
            break;
                
            case DKDContentType_Video: {
                // TODO: show video info
                messageLabel.text = [content messageText];
            }
            break;
                
            case DKDContentType_Page: {
                // TODO: show web page
                DIMWebpageContent *page = (DIMWebpageContent *)content;
                NSString *title = page.title;
                NSString *desc = page.desc;
                NSURL *url = page.URL;
                NSData *icon = page.icon;
                
                // title
                title = [title stringByAppendingString:@"\n"];
                // desc
                if (desc.length == 0) {
                    NSString *format = NSLocalizedString(@"[Web:%@]", nil);
                    desc = [NSString stringWithFormat:format, url];
                }
                // icon
                UIImage *image = nil;
                if (icon.length > 0) {
                    image = [UIImage imageWithData:icon];
                }
                
                NSMutableAttributedString *attrText;
                attrText = [[NSMutableAttributedString alloc] init];
                
                if (image) {
                    NSTextAttachment *att = [[NSTextAttachment alloc] init];
                    att.image = image;
                    att.bounds = CGRectMake(0, 0, 12, 12);
                    
                    NSAttributedString *head;
                    head = [NSAttributedString attributedStringWithAttachment:att];
                    [attrText appendAttributedString:head];
                }
                
                NSMutableAttributedString *line1, *line2;
                line1 = [[NSMutableAttributedString alloc] initWithString:title];
                line2 = [[NSMutableAttributedString alloc] initWithString:desc];
                [line2 addAttribute:NSForegroundColorAttributeName
                             value:[UIColor lightGrayColor]
                             range:NSMakeRange(0, desc.length)];
                
                [attrText appendAttributedString:line1];
                [attrText appendAttributedString:line2];
                
                messageLabel.attributedText = attrText;
                
                [messageLabel addClickTarget:self action:@selector(openURL:)];
            }
            break;
                
            default: {
                NSString *text;
                if ([content isKindOfClass:[DIMCommand class]]) {
                    text = [(DIMCommand *)content messageWithSender:sender];
                } else {
                    text = [content messageText];
                }
                if (!text) {
                    // unsupported message type
                    NSString *format = NSLocalizedString(@"This client doesn't support this message type: %u", nil);
                    text = [NSString stringWithFormat:format, content.type];
                }
                messageLabel.text = text;
            }
            break;
        }
        
        [self setNeedsLayout];
    }
}

- (void)zoomIn:(UITapGestureRecognizer *)sender {
    if(self.delegate != nil){
        [self.delegate messageCell:self showImage:_msg.image];
    }
}

-(void)didLongPressHappen:(id)sender{
    
    if (sender == self.longPressGuesture){
        
        if (self.longPressGuesture.state == UIGestureRecognizerStateBegan){
            
            if(!self.messageLabel.hidden){
            
                [self becomeFirstResponder];
                [self popMemu];
            }
        }
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copyClick) )
    {
        return YES;
    }
    return NO;
}

- (void)popMemu
{
    UIMenuItem *menuItem_1 = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", @"title") action:@selector(copyClick)];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.menuItems = [NSArray arrayWithObjects:menuItem_1, nil];
    
    CGFloat width = 40.0;
    CGFloat height = 40.0;
    CGFloat x = self.messageLabel.frame.origin.x;
    CGFloat y = self.frame.origin.y + 10.0;
    [menuController setTargetRect:CGRectMake(x, y, width, height) inView:self.superview];
    [menuController setMenuVisible:YES animated:YES];
}

- (void)copyClick{
    [[UIPasteboard generalPasteboard] setString:self.messageLabel.text];
}

@end
