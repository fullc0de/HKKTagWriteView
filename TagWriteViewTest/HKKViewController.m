//
//  HKKViewController.m
//  TagWriteViewTest
//
//  Created by kyokook on 2014. 1. 11..
//  Copyright (c) 2014 rhlab. All rights reserved.
//

#import "Foundation/Foundation.h"
#import "HKKViewController.h"
#import "HKKTagWriteView.h"
#if __clang__ && (__clang_major__ >= 6)
#import "TagWriteViewTest-Swift.h"
#endif


@interface HKKViewController ()
<
    HKKTagWriteViewDelegate,
    TagWriteViewDelegate
>

@property (nonatomic, assign) IBOutlet HKKTagWriteView *tagWriteView;
#if __clang__ && (__clang_major__ >= 6)
@property (nonatomic, weak) IBOutlet TagWriteView *swiftTagView;
@property (weak, nonatomic) IBOutlet UIButton *addInputtedTagButton;

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
    _swiftTagView.delegate = self;
    _swiftTagView.allowToUseSingleSpace = YES;
    _swiftTagView.allowDuplication = YES;
    _swiftTagView.insetForTag = UIEdgeInsetsMake(9, 7, 6, 7);
    CGRect deleteFrame = _swiftTagView.deleteButton.frame;
    deleteFrame.size = CGSizeMake(17, 17);
    _swiftTagView.deleteButton.frame = deleteFrame;
    _swiftTagView.scrollView.contentInset = UIEdgeInsetsMake(0, 20.0, 0, 20.0);
    _swiftTagView.placeHolderForInput = [[NSAttributedString alloc] initWithString:@"input tag.." attributes: @{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
    _swiftTagView.minimumWidthOfTag = 80.0;
    _swiftTagView.deleteButton.backgroundColor = [UIColor clearColor];
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

- (IBAction)addInputtedTagDidPush:(id)sender {
#if __clang__ && (__clang_major__ >= 6)
    [_swiftTagView submitInputtedTagWithAnimated:YES];
#endif
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

- (BOOL)tagWriteView:(HKKTagWriteView *)view shouldChangeText:(NSString *)text
{
    return text.length < 10;
}

- (void)tagWriteViewWithView:(TagWriteView * _Null_unspecified)view didMakeTag:(NSString * _Null_unspecified)tag
{
    NSLog(@"[swift] added tag = %@", tag);
}

- (void)tagWriteViewWithView:(TagWriteView * _Null_unspecified)view didRemoveTag:(NSString * _Null_unspecified)tag
{
    NSLog(@"[swift] removed tag = %@", tag);
}

- (BOOL)tagWriteViewWithView:(TagWriteView * _Null_unspecified)view shouldChangeText:(NSString * _Null_unspecified)text
{
    return text.length < 10;
}
@end
