//
//  HKKViewController.m
//  TagWriteViewTest
//
//  Created by kyokook on 2014. 1. 11..
//  Copyright (c) 2014 rhlab. All rights reserved.
//

#import "HKKViewController.h"
#import "HKKTagWriteView.h"
#import "TagWriteViewTest-Swift.h"


@interface HKKViewController ()
<
    HKKTagWriteViewDelegate
>

@property (nonatomic, assign) IBOutlet HKKTagWriteView *tagWriteView;
@property (nonatomic, weak) IBOutlet TagWriteView *swiftTagView;
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
    
    _swiftTagView.allowToUseSingleSpace = YES;
    [_swiftTagView setBackgroundColor:[UIColor greenColor]];
    [_swiftTagView addTags:@[@"sw_hello", @"sw_UX", @"sw_congratulation"]];
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
