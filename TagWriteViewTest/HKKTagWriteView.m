//
//  HKKTagWriteView.m
//  TagWriteViewTest
//
//  Created by kyokook on 2014. 1. 11..
//  Copyright (c) 2014 rhlab. All rights reserved.
//

#import "HKKTagWriteView.h"

@import QuartzCore;

@interface HKKTagWriteView  ()
<
    UITextViewDelegate
>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *tagViews;
@property (nonatomic, strong) UITextView *inputView;
@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong) NSMutableArray *tagsMade;

@property (nonatomic, assign) BOOL readyToDelete;

@end

@implementation HKKTagWriteView

#pragma mark - Life Cycle
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initProperties];
        [self initControls];
        
        [self reArrangeSubViews];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initProperties];
    [self initControls];
    
    [self reArrangeSubViews];
}

#pragma mark - Property Get / Set
- (void)setFont:(UIFont *)font
{
    _font = font;
    for (UIButton *btn in _tagViews)
    {
        [btn.titleLabel setFont:_font];
    }
}

- (void)setTagBackgroundColor:(UIColor *)tagBackgroundColor
{
    _tagBackgroundColor = tagBackgroundColor;
    for (UIButton *btn in _tagViews)
    {
        [btn setBackgroundColor:_tagBackgroundColor];
    }
    
    _inputView.layer.borderColor = _tagBackgroundColor.CGColor;
    _inputView.textColor = _tagBackgroundColor;
}

- (void)setTagForegroundColor:(UIColor *)tagForegroundColor
{
    _tagForegroundColor = tagForegroundColor;
    for (UIButton *btn in _tagViews)
    {
        [btn setTitleColor:_tagForegroundColor forState:UIControlStateNormal];
    }
}

- (void)setMaxTagLength:(int)maxTagLength
{
    _maxTagLength = maxTagLength;
}

- (NSArray *)tags
{
    return _tagsMade;
}

- (void)setFocusOnAddTag:(BOOL)focusOnAddTag
{
    _focusOnAddTag = focusOnAddTag;
    if (_focusOnAddTag)
    {
        [_inputView becomeFirstResponder];
    }
    else
    {
        [_inputView resignFirstResponder];
    }
}

#pragma mark - Interfaces
- (void)clear
{
    _inputView.text = @"";
    [_tagsMade removeAllObjects];
    [self reArrangeSubViews];
}

- (void)setTextToInputSlot:(NSString *)text
{
    _inputView.text = text;
}

- (void)addTags:(NSArray *)tags
{
    for (NSString *tag in tags)
    {
        NSArray *result = [_tagsMade filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@", tag]];
        if (result.count == 0)
        {
            [_tagsMade addObject:tag];
        }
    }
    
    [self reArrangeSubViews];
}

- (void)removeTags:(NSArray *)tags
{
    for (NSString *tag in tags)
    {
        NSArray *result = [_tagsMade filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@", tag]];
        if (result)
        {
            [_tagsMade removeObjectsInArray:result];
        }
    }
    [self reArrangeSubViews];
}

- (void)addTagToLast:(NSString *)tag animated:(BOOL)animated
{
    for (NSString *t in _tagsMade)
    {
        if ([tag isEqualToString:t])
        {
            NSLog(@"DUPLICATED!");
            return;
        }
    }
    
    [_tagsMade addObject:tag];
    
    _inputView.text = @"";
    
    [self addTagViewToLast:tag animated:animated];
    [self layoutInputAndScroll];
    
    if ([_delegate respondsToSelector:@selector(tagWriteView:didMakeTag:)])
    {
        [_delegate tagWriteView:self didMakeTag:tag];
    }
}

- (void)removeTag:(NSString *)tag animated:(BOOL)animated
{
    NSInteger foundedIndex = -1;
    for (NSString *t in _tagsMade)
    {
        if ([tag isEqualToString:t])
        {
            NSLog(@"FOUND!");
            foundedIndex = (NSInteger)[_tagsMade indexOfObject:t];
            break;
        }
    }
    
    if (foundedIndex == -1)
    {
        return;
    }

    [_tagsMade removeObjectAtIndex:foundedIndex];

    [self removeTagViewWithIndex:foundedIndex animated:animated completion:^(BOOL finished){
        [self layoutInputAndScroll];
    }];
    
    if ([_delegate respondsToSelector:@selector(tagWriteView:didRemoveTag:)])
    {
        [_delegate tagWriteView:self didRemoveTag:tag];
    }
}

#pragma mark - Internals
- (void)initControls
{
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.scrollsToTop = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_scrollView];

    _inputView = [[UITextView alloc] initWithFrame:CGRectInset(self.bounds, 0, _tagGap)];
    _inputView.autocorrectionType = UITextAutocorrectionTypeNo;
    _inputView.delegate = self;
    _inputView.returnKeyType = UIReturnKeyDone;
    _inputView.contentInset = UIEdgeInsetsMake(-6, 0, 0, 0);
    _inputView.scrollsToTop = NO;
    _inputView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    [_scrollView addSubview:_inputView];
    
    _deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(30, 0, 17, 17)];
    [_deleteButton setBackgroundImage:[UIImage imageNamed:@"btn_tag_delete"] forState:UIControlStateNormal];
    [_deleteButton addTarget:self action:@selector(deleteTagDidPush:) forControlEvents:UIControlEventTouchUpInside];
    _deleteButton.hidden = YES;
}

- (void)initProperties
{
    _font = [UIFont systemFontOfSize:14.0f];
    _tagBackgroundColor = [UIColor darkGrayColor];
    _tagForegroundColor = [UIColor whiteColor];
    _maxTagLength = 20;
    _tagGap = 4.0f;
    
    _tagsMade = [NSMutableArray array];
    _tagViews = [NSMutableArray array];
    
    _readyToDelete = NO;
}

- (void)addTagViewToLast:(NSString *)newTag animated:(BOOL)animated
{
    CGFloat posX = [self posXForObjectNextToLastTagView];
    UIButton *tagBtn = [self tagButtonWithTag:newTag posX:posX];
    [_tagViews addObject:tagBtn];
    tagBtn.tag = [_tagViews indexOfObject:tagBtn];
    [_scrollView addSubview:tagBtn];
    
    if (animated)
    {
        tagBtn.alpha = 0.0f;
        [UIView animateWithDuration:0.25 animations:^{
            tagBtn.alpha = 1.0f;
        }];
    }
    
}

- (void)removeTagViewWithIndex:(NSUInteger)index animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    NSAssert(index < _tagViews.count, @"incorrected index");
    if (index >= _tagViews.count)
    {
        return;
    }
    
    UIView *deletedView = [_tagViews objectAtIndex:index];
    [deletedView removeFromSuperview];
    [_tagViews removeObject:deletedView];
    
    void (^layoutBlock)(void) = ^{
        CGFloat posX = _tagGap;
        for (int idx = 0; idx < _tagViews.count; ++idx)
        {
            UIView *view = [_tagViews objectAtIndex:idx];
            CGRect viewFrame = view.frame;
            viewFrame.origin.x = posX;
            view.frame = viewFrame;
            
            posX += viewFrame.size.width + _tagGap;
            
            view.tag = idx;
        }
    };
    
    if (animated)
    {
        [UIView animateWithDuration:0.25 animations:layoutBlock completion:completion];
    }
    else
    {
        layoutBlock();
    }

}

- (void)reArrangeSubViews
{
    CGFloat accumX = _tagGap;
    
    NSMutableArray *newTags = [[NSMutableArray alloc] initWithCapacity:_tagsMade.count];
    for (NSString *tag in _tagsMade)
    {
        UIButton *tagBtn = [self tagButtonWithTag:tag posX:accumX];
        [newTags addObject:tagBtn];
        tagBtn.tag = [newTags indexOfObject:tagBtn];
        
        accumX += tagBtn.frame.size.width + _tagGap;
        [_scrollView addSubview:tagBtn];
    }
    
    for (UIView *oldTagView in _tagViews)
    {
        [oldTagView removeFromSuperview];
    }
    _tagViews = newTags;
    
    [self layoutInputAndScroll];
}

- (void)layoutInputAndScroll
{
    CGFloat accumX = [self posXForObjectNextToLastTagView];

    CGRect inputRect = _inputView.frame;
    inputRect.origin.x = accumX;
    inputRect.origin.y = _tagGap + 6.0f;
    inputRect.size.width = [self widthForInputViewWithText:_inputView.text];
    inputRect.size.height = self.frame.size.height - 13.0f;
    _inputView.frame = inputRect;
    _inputView.font = _font;
    _inputView.layer.borderColor = _tagBackgroundColor.CGColor;
    _inputView.layer.borderWidth = 1.0f;
    _inputView.layer.cornerRadius = _inputView.frame.size.height * 0.5f;
    _inputView.backgroundColor = [UIColor clearColor];
    _inputView.textColor = _tagBackgroundColor;

    CGSize contentSize = _scrollView.contentSize;
    contentSize.width = accumX + inputRect.size.width + 20.0f;
    _scrollView.contentSize = contentSize;

    [self setScrollOffsetToShowInputView];
}

- (void)setScrollOffsetToShowInputView
{
    CGRect inputRect = _inputView.frame;
    CGFloat scrollingDelta = (inputRect.origin.x + inputRect.size.width) - (_scrollView.contentOffset.x + _scrollView.frame.size.width);
    if (scrollingDelta > 0)
    {
        CGPoint scrollOffset = _scrollView.contentOffset;
        scrollOffset.x += scrollingDelta + 40.0f;
        _scrollView.contentOffset = scrollOffset;
    }
}

- (CGFloat)widthForInputViewWithText:(NSString *)text
{
    return MAX(50.0, [text sizeWithAttributes:@{NSFontAttributeName:_font}].width + 25.0f);
}

- (CGFloat)posXForObjectNextToLastTagView
{
    CGFloat accumX = _tagGap;
    if (_tagViews.count)
    {
        UIView *last = _tagViews.lastObject;
        accumX = last.frame.origin.x + last.frame.size.width + _tagGap;
    }
    return accumX;
}

- (UIButton *)tagButtonWithTag:(NSString *)tag posX:(CGFloat)posX
{
    UIButton *tagBtn = [[UIButton alloc] init];
    [tagBtn.titleLabel setFont:_font];
    [tagBtn setBackgroundColor:_tagBackgroundColor];
    [tagBtn setTitleColor:_tagForegroundColor forState:UIControlStateNormal];
    [tagBtn addTarget:self action:@selector(tagButtonDidPushed:) forControlEvents:UIControlEventTouchUpInside];
    [tagBtn setTitle:tag forState:UIControlStateNormal];
    
    CGRect btnFrame = tagBtn.frame;
    btnFrame.origin.x = posX;
    btnFrame.origin.y = _tagGap + 6.0f;
    btnFrame.size.width = [tagBtn.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:_font}].width + (tagBtn.layer.cornerRadius * 2.0f) + 20.0f;
    btnFrame.size.height = self.frame.size.height - 13.0f;
    tagBtn.layer.cornerRadius = btnFrame.size.height * 0.5f;
    tagBtn.frame = CGRectIntegral(btnFrame);
    
    NSLog(@"btn frame [%@] = %@", tag, NSStringFromCGRect(tagBtn.frame));
    
    return tagBtn;
}

- (void)detectBackspace
{
    if (_inputView.text.length == 0)
    {
        if (_readyToDelete)
        {
            // remove lastest tag
            if (_tagsMade.count > 0)
            {
                NSString *deletedTag = _tagsMade.lastObject;
                [self removeTag:deletedTag animated:YES];
                _readyToDelete = NO;
            }
        }
        else
        {
            _readyToDelete = YES;
        }
    }
}

#pragma mark - UI Actions
- (void)tagButtonDidPushed:(id)sender
{
    UIButton *btn = sender;
    NSLog(@"tagButton pushed: %@, idx = %ld", btn.titleLabel.text, (long)btn.tag);
    
    if (_deleteButton.hidden == NO && btn.tag == _deleteButton.tag)
    {
        // hide delete button
        _deleteButton.hidden = YES;
        [_deleteButton removeFromSuperview];
    }
    else
    {
        // show delete button
        CGRect newRect = _deleteButton.frame;
        newRect.origin.x = btn.frame.origin.x + btn.frame.size.width - (newRect.size.width * 0.7f);
        newRect.origin.y = _inputView.frame.origin.y - 8.0f;
        _deleteButton.frame = newRect;
        _deleteButton.tag = btn.tag;
        
        if (_deleteButton.superview == nil)
        {
            [_scrollView addSubview:_deleteButton];
        }
        _deleteButton.hidden = NO;
    }
}

- (void)deleteTagDidPush:(id)sender
{
    NSLog(@"tag count = %d,  button tag = %d", _tagsMade.count, _deleteButton.tag);
    NSAssert(_tagsMade.count > _deleteButton.tag, @"out of range");
    if (_tagsMade.count <= _deleteButton.tag)
    {
        return;
    }
    
    _deleteButton.hidden = YES;
    [_deleteButton removeFromSuperview];
    
    NSString *tag = [_tagsMade objectAtIndex:_deleteButton.tag];
    [self removeTag:tag animated:YES];
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@" "] || [text isEqualToString:@"\n"])
    {
        if (textView.text.length > 0)
        {
            [self addTagToLast:textView.text animated:YES];
            textView.text = @"";
        }

        if ([text isEqualToString:@"\n"])
        {
            [textView resignFirstResponder];
        }

        return NO;
    }
    
    CGFloat currentWidth = [self widthForInputViewWithText:textView.text];
    CGFloat newWidth = 0;
    NSString *newText = nil;
    
    if (text.length == 0)
    {
        // delete
        if (textView.text.length)
        {
            newText = [textView.text substringWithRange:NSMakeRange(0, textView.text.length - range.length)];
        }
        else
        {
            [self detectBackspace];
            return NO;
        }
    }
    else
    {
        if (textView.text.length + text.length > _maxTagLength)
        {
            return NO;
        }
        newText = [NSString stringWithFormat:@"%@%@", textView.text, text];
    }
    newWidth = [self widthForInputViewWithText:newText];
    
    CGRect inputRect = _inputView.frame;
    inputRect.size.width = newWidth;
    _inputView.frame = inputRect;

    CGFloat widthDelta = newWidth - currentWidth;
    CGSize contentSize = _scrollView.contentSize;
    contentSize.width += widthDelta;
    _scrollView.contentSize = contentSize;
    
    [self setScrollOffsetToShowInputView];
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if ([_delegate respondsToSelector:@selector(tagWriteView:didChangeText:)])
    {
        [_delegate tagWriteView:self didChangeText:textView.text];
    }
    
    if (_deleteButton.hidden == NO)
    {
        _deleteButton.hidden = YES;
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([_delegate respondsToSelector:@selector(tagWriteViewDidBeginEditing:)])
    {
        [_delegate tagWriteViewDidBeginEditing:self];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([_delegate respondsToSelector:@selector(tagWriteViewDidEndEditing:)])
    {
        [_delegate tagWriteViewDidEndEditing:self];
    }
}
@end



















