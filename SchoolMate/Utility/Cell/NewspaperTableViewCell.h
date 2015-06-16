//
//  NewspaperTableViewCell.h
//  SchoolMate
//
//  Created by SuperDanny on 15/6/15.
//  Copyright (c) 2015年 libiwu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommentItemView.h"

@interface NewspaperTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet CommentItemView *likeItemView;
@property (weak, nonatomic) IBOutlet CommentItemView *commentItemView;

@end
