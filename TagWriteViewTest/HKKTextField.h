//
//  HKKTextField.h
//  TagWriteViewTest
//
//  Created by kyokook on 2014. 1. 11..
//  Copyright (c) 2014 rhlab. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HKKTextFieldDelegate;

@interface HKKTextField : UITextField

@end

@protocol HKKTextFieldDelegate <UITextFieldDelegate>
@optional
- (void)textFieldDidDetectBackspace:(HKKTextField *)textField;
@end