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
#import "NSDate+Extension.h"

#import "DIMProfile+Extension.h"
#import "DIMInstantMessage+Extension.h"

#import "WebViewController.h"

#import "User.h"

#import "MessageProcessor.h"

#import "ZoomInViewController.h"

#import "MsgCell.h"

@interface MsgCell ()

@property (strong, nonatomic) UIImage *picture;

@end

@implementation MsgCell

+(NSString *)timeString:(DKDInstantMessage *)msg{
    
    // time
    NSTimeInterval timestamp = [[msg objectForKey:@"time"] doubleValue];
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:timestamp];
    NSString *time = NSStringFromDate(date);
    return time;
}

+ (CGSize)sizeWithMessage:(DKDInstantMessage *)iMsg bounds:(CGRect)rect {
    NSString *text = nil;
    if (iMsg.content.type == DIMContentType_Text) {
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
    
    NSString *time = [MsgCell timeString:iMsg];
    if (time.length > 0) {
        cellHeight += 20;
    }
    
    if (cellHeight < 80) {
        cellHeight = 80;
    }
    return CGSizeMake(cellWidth, cellHeight);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (UIImage *)picture {
    if (!_picture) {
        _picture = _msg.image;
    }
    return _picture;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    id cell = self;
    UIImageView *messageImageView = [cell messageImageView];
    UILabel *messageLabel = [cell messageLabel];
    
    CGFloat cellWidth = self.bounds.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    
    // message
    UIFont *font = messageLabel.font;
    NSString *text = messageLabel.text;
    CGSize size;
    
    if (_picture) {
        size = [UIScreen mainScreen].bounds.size;
        CGFloat max_width = MIN(size.width, size.height) * 0.382;
        if (_picture.size.width > max_width) {
            CGFloat ratio = max_width / _picture.size.width;
            size = CGSizeMake(_picture.size.width * ratio, _picture.size.height * ratio);
        } else {
            size = _picture.size;
        }
        
        messageImageView.hidden = YES;
    } else {
        size = CGSizeMake(msgWidth - edges.left - edges.right, MAXFLOAT);
        size = [text sizeWithFont:font maxSize:size];
        messageImageView.hidden = NO;
    }
    
    CGFloat labelHeight = size.height;
    
    CGRect imageFrame = messageImageView.frame;
    CGRect labelFrame = CGRectMake(imageFrame.origin.x + edges.left,
                                   imageFrame.origin.y + edges.top,
                                   size.width, labelHeight);
    
    if(messageImageView.hidden){
        labelFrame = CGRectMake(imageFrame.origin.x + edges.left / 2.0,
                                imageFrame.origin.y + edges.top,
                                size.width, labelHeight);
    }
    
    imageFrame.size = CGSizeMake(labelFrame.size.width + edges.left + edges.right,
                                 labelFrame.size.height + edges.top + edges.bottom);
    messageImageView.frame = imageFrame;
    messageLabel.frame = labelFrame;
    
    // resize content view
    CGFloat cellHeight = imageFrame.origin.y + imageFrame.size.height;
    if (cellHeight < 80) {
        cellHeight = 80;
    }
    CGRect rect = CGRectMake(0, 0, cellWidth, cellHeight);
    self.bounds = rect;
    self.contentView.frame = rect;
}

- (void)setMsg:(DKDInstantMessage *)msg {
    if (![_msg isEqual:msg]) {
        _msg = msg;
        
        self.picture = msg.image;
        
        id cell = self;
        UILabel *timeLabel = [cell timeLabel];
        UIImageView *avatarImageView = [cell avatarImageView];
        UILabel *messageLabel = [cell messageLabel];
        
        DIMEnvelope *env = msg.envelope;
        DIMID *sender = MKMIDFromString(env.sender);
        DIMContent *content = msg.content;
        DIMProfile *profile = DIMProfileForID(sender);
        
        // time
        NSString *time = [MsgCell timeString:msg];
        if (time.length > 0) {
            timeLabel.text = time;
            // resize
            UIFont *font = timeLabel.font;
            CGSize size = CGSizeMake(200, MAXFLOAT);
            size = [time sizeWithFont:font maxSize:size];
            size = CGSizeMake(size.width + 16, 16);
            CGRect rect = CGRectMake(0, 0,
                                     size.width, size.height);
            timeLabel.bounds = rect;
            [timeLabel roundedCorner];
            timeLabel.hidden = NO;
        } else {
            timeLabel.bounds = CGRectMake(0, 0, 0, 0);
            timeLabel.text = @"";
            timeLabel.hidden = YES;
        }
        
        // avatar
        CGRect avatarFrame = avatarImageView.frame;
        UIImage *image = [profile avatarImageWithSize:avatarFrame.size];
        if (!image) {
            image = [UIImage imageNamed:@"AppIcon"];
        }
        [avatarImageView setImage:image];
        
        // message
        switch (msg.content.type) {
            case DIMContentType_Text: {
                // show text
                messageLabel.text = [(DIMTextContent *)content text];
                // double click to zoom in
                [messageLabel addDoubleClickTarget:self action:@selector(zoomIn:)];
            }
            break;
                
            case DIMContentType_File: {
                // TODO: show file info
                NSString *filename = [(DIMFileContent *)content filename];
                NSString *format = NSLocalizedString(@"[File:%@]", nil);
                messageLabel.text = [NSString stringWithFormat:format, filename];
            }
            break;
                
            case DIMContentType_Image: {
                // show image
                if (_picture) {
                    CGSize size = [UIScreen mainScreen].bounds.size;
                    CGFloat max_width = MIN(size.width, size.height) * 0.382;
                    
                    if (_picture.size.width > max_width) {
                        CGFloat ratio = max_width / _picture.size.width;
                        size = CGSizeMake(_picture.size.width * ratio, _picture.size.height * ratio);
                    } else {
                        size = _picture.size;
                    }
                    
                    NSTextAttachment *att = [[NSTextAttachment alloc] init];
                    att.image = _picture;
                    att.bounds = CGRectMake(0, 0, size.width, size.height);
                    NSAttributedString *as = [NSAttributedString attributedStringWithAttachment:att];
                    messageLabel.attributedText = as;
                    messageLabel.bounds = CGRectMake(0, 0, size.width, size.height);
                } else {
                    NSString *filename = [(DIMImageContent *)content filename];
                    NSString *format = NSLocalizedString(@"[Image:%@]", nil);
                    messageLabel.text = [NSString stringWithFormat:format, filename];
                }
                
                [messageLabel addClickTarget:self action:@selector(zoomIn:)];
            }
            break;
                
            case DIMContentType_Audio: {
                // TODO: show audio info
                NSString *filename = [(DIMAudioContent *)content filename];
                NSString *format = NSLocalizedString(@"[Voice:%@]", nil);
                messageLabel.text = [NSString stringWithFormat:format, filename];
            }
            break;
                
            case DIMContentType_Video: {
                // TODO: show video info
                NSString *filename = [(DIMVideoContent *)content filename];
                NSString *format = NSLocalizedString(@"[Movie:%@]", nil);
                messageLabel.text = [NSString stringWithFormat:format, filename];
            }
            break;
                
            case DIMContentType_Page: {
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
                // unsupported message type
                NSString *format = NSLocalizedString(@"This client doesn't support this message type: %u", nil);
                messageLabel.text = [NSString stringWithFormat:format, content.type];
            }
            break;
        }
        
        [self setNeedsLayout];
    }
}

- (void)zoomIn:(UITapGestureRecognizer *)sender {
    NSLog(@"zoomIn: %@", _msg.content);
    DIMContent *content = _msg.content;
    switch (content.type) {
        case DIMContentType_Image: {
            ZoomInViewController *zoomIn = [UIStoryboard instantiateViewControllerWithIdentifier:@"zoomInController" storyboardName:@"Conversations"];
            zoomIn.msg = _msg;
            
            UIWindow *window = [UIApplication sharedApplication].delegate.window;
            UIViewController *root = window.rootViewController;
            UIViewController *top = root.presentedViewController;
            [top presentViewController:zoomIn animated:NO completion:nil];
        }
            break;
            
        default:
            break;
    }
}

- (void)openURL:(UITapGestureRecognizer *)sender {
    
    DIMContent *content = _msg.content;
    if (content.type != DIMContentType_Page) {
        return ;
    }
    NSURL *url = [(DIMWebpageContent *)content URL];
    NSLog(@"opening URL: %@", url);
    
    WebViewController *vc;
    vc = [UIStoryboard instantiateViewControllerWithIdentifier:@"webPage"
                                                storyboardName:@"Main"];
    vc.url = url;
    
    UIViewController *root;
    root = [UIApplication sharedApplication].delegate.window.rootViewController;
    [root.presentedViewController showViewController:vc sender:self];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    id cell = self;
    // avatar
    UIImageView *avatarImageView = [cell avatarImageView];
    [avatarImageView roundedCorner];
    [avatarImageView addClickTarget:self action:@selector(onAvatarClicked:)];
    
    // message
    UIImageView *messageImageView = [cell messageImageView];
    UIImage *image = messageImageView.image;
    if (image) {
        CGSize size = image.size;
        CGFloat x = size.width * 0.618;
        CGFloat y = size.height * 0.618;
        /* CGFloat top, CGFloat left, CGFloat bottom, CGFloat right */
        UIEdgeInsets insets = UIEdgeInsetsMake(y, x, y + 1, x + 1);
        image = [image resizableImageWithCapInsets:insets];
    }
    messageImageView.image = image;
}

- (void)onAvatarClicked:(UITapGestureRecognizer *)gestureRecognizer {
    
    [self.controller performSegueWithIdentifier:@"profileSegue" sender:self];
}

@end

#pragma mark -

@implementation SentMsgCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    CGFloat space = 5;
    
    CGRect avatarFrame = _avatarImageView.frame;
    CGRect msgImageFrame = _messageImageView.frame;
    CGRect msgLabelFrame = _messageLabel.frame;
    
    // adjust position of message box
    msgImageFrame.origin.x = avatarFrame.origin.x - space - msgImageFrame.size.width;
    msgLabelFrame.origin.x = msgImageFrame.origin.x + edges.left;
    
    if(self.messageImageView.hidden){
        msgLabelFrame.origin.x = msgImageFrame.origin.x + edges.left + edges.right / 2.0;
    }
    
    _messageImageView.frame = msgImageFrame;
    _messageLabel.frame = msgLabelFrame;
    
    // error info button
    DIMMessageState state = _msg.state;
    NSString *error = _msg.error;
    if (state == DIMMessageState_Error && error) {
        CGRect frame = _infoButton.frame;
        CGFloat x, y;
        x = msgImageFrame.origin.x - frame.size.width;
        y = msgImageFrame.origin.y + (msgImageFrame.size.height - frame.size.height) * 0.5;
        frame.origin = CGPointMake(x, y);
        _infoButton.frame = frame;
        _infoButton.hidden = NO;
    } else {
        _infoButton.hidden = YES;
    }
}

- (void)setMsg:(DKDInstantMessage *)msg {
    [super setMsg:msg];
    
    // error info button
    DIMMessageState state = _msg.state;
    NSString *error = _msg.error;
    if (state == DIMMessageState_Error && error) {
        // message
        MessageButton *btn = (MessageButton *)_infoButton;
        btn.title = NSLocalizedString(@"Failed to send this message.", nil);
        btn.message = error;
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // error info button
    [_infoButton roundedCorner];
}

@end

@implementation ReceivedMsgCell

+ (CGSize)sizeWithMessage:(DKDInstantMessage *)iMsg bounds:(CGRect)rect {
    CGSize size = [super sizeWithMessage:iMsg bounds:rect];
    size.height += 24;
    return size;
}

- (void)setMsg:(DKDInstantMessage *)msg {
    [super setMsg:msg];
    
    DIMEnvelope *env = msg.envelope;
    DIMID *sender = MKMIDFromString(env.sender);
    
    // name
    _nameLabel.text = readable_name(sender);
}

@end

@implementation CommandMsgCell

+ (CGSize)sizeWithMessage:(DKDInstantMessage *)iMsg bounds:(CGRect)rect {
    NSString *text = nil;
    if (iMsg.content.type == DIMContentType_Text) {
        text = [(DIMTextContent *)iMsg.content text];
    }
    
    CGFloat cellWidth = rect.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 10, 10, 10);

    CGSize size = CGSizeMake(msgWidth - edges.left - edges.right,
                             MAXFLOAT);
    UIFont *font = [UIFont systemFontOfSize:14];
    size = [text sizeWithFont:font maxSize:size];
    CGFloat cellHeight = size.height + edges.top + edges.bottom + 24;
    return CGSizeMake(cellWidth, cellHeight);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat cellWidth = self.bounds.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 10, 10, 10);
    
    UILabel *timeLabel = [self timeLabel];
    UILabel *messageLabel = [self messageLabel];
    
    CGRect timeFrame = timeLabel.frame;
    
    NSString *text = nil;
    if (_msg.content.type == DIMContentType_Text) {
        text = [(DIMTextContent *)_msg.content text];
    }
    if (text.length > 0) {
        UIFont *font = messageLabel.font;
        CGSize size = CGSizeMake(msgWidth, MAXFLOAT);
        size = [text sizeWithFont:font maxSize:size];
        size.width += edges.left + edges.right;
        size.height += edges.top + edges.bottom;
        CGRect frame = CGRectMake((cellWidth - size.width) * 0.5,
                                  timeFrame.origin.y + timeFrame.size.height,
                                  size.width, size.height);
        messageLabel.frame = frame;
    }
    
    // resize content view
    CGRect msgFrame = messageLabel.frame;
    CGFloat cellHeight = msgFrame.origin.y + msgFrame.size.height + edges.bottom;
    CGRect rect = CGRectMake(0, 0, cellWidth, cellHeight);
    self.bounds = rect;
    self.contentView.frame = rect;
}

- (void)setMsg:(DKDInstantMessage *)msg {
    if (![_msg isEqual:msg]) {
        _msg = msg;
        
        CGFloat cellWidth = self.bounds.size.width;
        CGFloat msgWidth = cellWidth * 0.618;
        
        // time
        NSString *time = [MsgCell timeString:msg];
        UILabel *timeLabel = [self timeLabel];
        if (time.length > 0) {
            timeLabel.text = time;
            // resize
            UIFont *font = timeLabel.font;
            CGSize size = CGSizeMake(msgWidth, MAXFLOAT);
            size = [time sizeWithFont:font maxSize:size];
            size = CGSizeMake(size.width + 16, 16);
            CGRect rect = CGRectMake(0, 0, size.width, size.height);
            timeLabel.bounds = rect;
            [timeLabel roundedCorner];
            timeLabel.hidden = NO;
        } else {
            timeLabel.bounds = CGRectMake(0, 0, 0, 0);
            timeLabel.text = @"";
            timeLabel.hidden = YES;
        }
        
        // message
        NSString *text = nil;
        if (msg.content.type == DIMContentType_Text) {
            text = [(DIMTextContent *)msg.content text];
        }
        UILabel *messageLabel = [self messageLabel];
        messageLabel.text = text;
        
        [self setNeedsLayout];
    }
}

@end
