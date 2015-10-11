//
//  HKKViewController.m
//  TagWriteViewTest
//
//  Created by kyokook on 2014. 1. 11..
//  Copyright (c) 2014 rhlab. All rights reserved.
//

#import "HKKViewController.h"
#import "HKKTagWriteView.h"
#if __clang__ && (__clang_major__ >= 6)
#import "TagWriteViewTest-Swift.h"
#endif


@interface HKKViewController ()
<
    HKKTagWriteViewDelegate
>

@property (nonatomic, assign) IBOutlet HKKTagWriteView *tagWriteView;
#if __clang__ && (__clang_major__ >= 6)
@property (nonatomic, weak) IBOutlet TagWriteView *swiftTagView;
#endif
@end

@implementation HKKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _tagWriteView.allowToUseSingleSpace = YES;
    _tagWriteView.delegate = self;
    [_tagWriteView setBackgroundColor:[UIColor yellowColor]];
    [_tagWriteView addTags:@[@"hello", @"UX", @"congratulation", @"google", @"ios", @"android"]];
    
#if __clang__ && (__clang_major__ >= 6)
    _swiftTagView.allowToUseSingleSpace = YES;
    _swiftTagView.verticalInsetForTag = UIEdgeInsetsMake(9, 0, 6, 0);
    _swiftTagView.sizeForDeleteButton = CGRectMake(0, 0, 17, 17);
    _swiftTagView.backgroundColorForDeleteButton = [UIColor clearColor];
    [_swiftTagView setBackgroundColor:[UIColor greenColor]];
    [_swiftTagView setDeleteButtonBackgroundImage:[UIImage imageNamed:@"btn_tag_delete"] state:UIControlStateNormal];
    [_swiftTagView addTags:@[@"sw_hello", @"sw_UX", @"sw_congratulation"]];
    
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - HKKTagWriteViewDelegate
- (void)tagWriteView:(HKKTagWriteView *)view didMakeTag:(NSString *)tag
{
    NSLog(@"added tag = %@", tag);
}

- (void)tagWriteView:(HKKTagWriteView *)view didRemoveTag:(NSString *)tag
{
    NSLog(@"removed tag = %@", tag);
}

@end
