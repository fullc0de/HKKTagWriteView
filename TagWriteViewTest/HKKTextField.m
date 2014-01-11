//
//  HKKTextField.m
//  TagWriteViewTest
//
//  Created by kyokook on 2014. 1. 11..
//  Copyright (c) 2014 rhlab. All rights reserved.
//

#import "HKKTextField.h"

@implementation HKKTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

#pragma mark - Overriden
- (void)deleteBackward
{
    if ([self.delegate respondsToSelector:@selector(textFieldDidDetectBackspace:)])
    {
        [self.delegate performSelector:@selector(textFieldDidDetectBackspace:) withObject:self];
    }
    
    [super deleteBackward];
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 10, 0);
}
@end
