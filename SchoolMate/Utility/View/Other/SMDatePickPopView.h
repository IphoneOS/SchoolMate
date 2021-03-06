//
//  SMDatePickPopView.h
//  SchoolMate
//
//  Created by libiwu on 15/6/15.
//  Copyright (c) 2015年 libiwu. All rights reserved.
//
//  时间选择器

#import <UIKit/UIKit.h>

typedef void(^DataPickerValueChange)(UIDatePicker *datePicker);
typedef void(^DataPickerDismiss)(UIDatePicker *datePicker);
@interface SMDatePickPopView : UIView

@property (nonatomic, copy  ) DataPickerValueChange valueChangeBlock;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, copy  ) DataPickerDismiss dismissBlock;
/**
 *  显示
 */
- (void)show;
/**
 *  隐藏
 */
- (void)dismiss;

- (void)setValueChange:(DataPickerValueChange)block;
- (void)setDismiss:(DataPickerDismiss)dismissBlock;
@end
