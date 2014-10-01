//
//  TagWriteView.swift
//  TagWriteViewTest
//
//  Created by kyokook on 2014. 7. 26..
//  Copyright (c) 2014년 rhlab. All rights reserved.
//

import UIKit
import Foundation
import QuartzCore

//
// It's an extension to support subscription on Array.
// It helps easily extract substring. Honestly, substringWithRange method of String is quite difficult to use for me.
// Thus, I looked for an alternative way and finally found a way making an extension of String to support subscript.
// The following link is where I referenced.
//
// http://stackoverflow.com/a/24046551/579236
//
extension String {
    subscript (r: Range<Int>) -> String {
        get {
            let startIndex = advance(self.startIndex, r.startIndex)
            let endIndex = advance(startIndex, r.endIndex - r.startIndex)
            
            return self[Range(start: startIndex, end: endIndex)]
        }
    }
}

public class TagWriteView : UIView
    , UITextViewDelegate
{
    
    // MARK: Public Properties
    public var font: UIFont = UIFont.systemFontOfSize(14.0) {
    didSet {
        for btn in tagViews {
            btn.titleLabel?.font = font
        }
    }
    }
    
    public var tagBackgroundColor: UIColor = UIColor.darkGrayColor() {
    didSet {
        for btn in tagViews {
            btn.backgroundColor = tagBackgroundColor
        }
        tagInputView.layer.borderColor = tagBackgroundColor.CGColor
        tagInputView.textColor = tagBackgroundColor
    }
    }
    
    public var tagForegroundColor: UIColor = UIColor.whiteColor() {
    didSet {
        for btn in tagViews {
            btn.setTitleColor(tagForegroundColor, forState: UIControlState.Normal)
        }
    }
    }
    
    public var tags: [String] {
        return tagsMade
    }
    
    public var maxTagLength = 20
    public var tagGap: CGFloat = 4.0
    public var allowToUseSingleSpace = false
    
    public var focusOnAddTag: Bool = false {
    didSet {
        if focusOnAddTag {
            tagInputView.becomeFirstResponder()
        } else {
            tagInputView.resignFirstResponder()
        }
    }
    }
    
    public var delegate: TagWriteViewDelegate?
    
    
    // MARK: Private Properties
    private var scrollView: UIScrollView!
    private var tagInputView: UITextView!
    private var deleteButton: UIButton!
    
    private var tagViews = [UIButton]()
    private var tagsMade = [String]()
    
    private var readyToDelete = false
    private var readyToFinishMaking = false
    
    
    // MARK: Initializers
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initControls()
        rearrangeSubViews()
    }
    
    // MARK: Override
    override public func awakeFromNib() {
        initControls()
        rearrangeSubViews()
    }
    
    // MARK: Interfaces
    public func clear() {
        tagInputView.text = ""
        tagsMade.removeAll(keepCapacity: false)
        rearrangeSubViews()
    }
    
    public func setTextToInputSlot(text: String) {
        tagInputView.text = text
    }
    
    public func addTags(tags: [String]) {
        for tag in tags {
            let result = tagsMade.filter({$0 == tag})
            if result.count == 0 {
                tagsMade.append(tag)
            }
        }
        
        rearrangeSubViews()
    }
    
    public func removeTags(tags: [String]) {
        var pickedIndexes = [Int]()
        for tag in tags {
            for (idx, value) in enumerate(tagsMade) {
                if value == tag {
                    pickedIndexes.append(idx)
                }
            }
        }
        
        for idx in pickedIndexes {
            tagsMade.removeAtIndex(idx)
        }
        
        rearrangeSubViews()
    }
    
    public func addTagToLast(tag: String, animated: Bool) {
        var newTag = tag.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        for t in tagsMade {
            if newTag == t {
                NSLog("DUPLICATED!")
                return
            }
        }
        
        tagsMade.append(newTag)
        
        tagInputView.text = ""
        addTagViewToLast(newTag, animated: animated)
        layoutInputAndScroll()
        
        delegate?.tagWriteView?(self, didChangeText: newTag)
    }

    public func removeTag(tag: String, animated: Bool) {
        var foundIndex = -1
        for (idx, value) in enumerate(tagsMade) {
            if tag == value {
                println("FOUND!")
                foundIndex = idx
            }
        }
        
        if foundIndex == -1 {
            return
        }
        
        tagsMade.removeAtIndex(foundIndex)
        removeTagView(foundIndex, animated: animated, { (finished: Bool) -> Void in
            self.layoutInputAndScroll()
        })
        
        delegate?.tagWriteView?(self, didRemoveTag: tag)
    }

    
    // MARK: UI Actions
    func tagButtonDidPushed(sender: AnyObject!) {
        let btn = sender as UIButton

        if deleteButton.hidden == false && btn.tag == deleteButton.tag {
            deleteButton.hidden = true
            deleteButton.removeFromSuperview()
        } else {
            var newRect = deleteButton.frame
            newRect.origin.x = btn.frame.origin.x + btn.frame.size.width - (newRect.size.width * 0.7)
            newRect.origin.y = tagInputView.frame.origin.y - 8.0
            deleteButton.frame = newRect
            deleteButton.tag = btn.tag
            if deleteButton.superview == nil {
                scrollView.addSubview(deleteButton)
            }
            deleteButton.hidden = false
        }
    }
    
    func deleteButtonDidPush(sender: AnyObject!) {
        if tagsMade.count <= deleteButton.tag {
            return
        }
        
        deleteButton.hidden = true
        deleteButton.removeFromSuperview()
        
        let tag = tagsMade[deleteButton.tag]
        removeTag(tag, animated: true)
    }
    
    // MARK: Internals
    private func initControls() {
        scrollView = UIScrollView(frame: self.bounds)
        scrollView.backgroundColor = UIColor.clearColor();
        scrollView.scrollsToTop = false;
        scrollView.showsVerticalScrollIndicator = false;
        scrollView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        addSubview(scrollView)
        
        tagInputView = UITextView(frame: CGRectInset(self.bounds, 0, tagGap))
        tagInputView.delegate = self
        tagInputView.autocorrectionType = UITextAutocorrectionType.No
        tagInputView.returnKeyType = UIReturnKeyType.Done
        tagInputView.contentInset = UIEdgeInsetsMake(-6, 0, 0, 0)
        tagInputView.scrollsToTop = false
        tagInputView.autoresizingMask = UIViewAutoresizing.FlexibleBottomMargin | UIViewAutoresizing.FlexibleTopMargin
        scrollView.addSubview(tagInputView)
        
        deleteButton = UIButton(frame: CGRectMake(30, 0, 17, 17))
        deleteButton.setBackgroundImage(UIImage(named: "btn_tag_delete"), forState: UIControlState.Normal)
        deleteButton.addTarget(self, action: "deleteButtonDidPush:", forControlEvents: UIControlEvents.TouchUpInside)
        deleteButton.hidden = true;
    }
    
    private func addTagViewToLast(newTag: String, animated: Bool) {
        var posX = posXForObjectNextToLastTagView()
        let tagBtn = tagButton(tagName: newTag, positionX: posX)
        tagBtn.tag = tagViews.count
        tagViews.append(tagBtn)
        scrollView.addSubview(tagBtn)
        
        if animated {
            tagBtn.alpha = 0.0
            UIView.animateWithDuration(0.25, animations: {tagBtn.alpha = 1.0})
        }
    }
    
    private func rearrangeSubViews() {
        var accumX = tagGap
        var newTagButtons: [UIButton] = Array()
        
        newTagButtons.reserveCapacity(tagsMade.count)
        for (index, tag) in enumerate(tagsMade) {
            let tagButton = self.tagButton(tagName: tag, positionX: accumX)
            newTagButtons.append(tagButton)
            tagButton.tag = index
            accumX += tagButton.frame.size.width + tagGap
            scrollView.addSubview(tagButton)
        }
        
        for oldTagButton in tagViews {
            oldTagButton.removeFromSuperview()
        }
        tagViews.removeAll(keepCapacity: false)
        tagViews += newTagButtons
        
        layoutInputAndScroll()
    }
    
    private func tagButton(tagName tag: String, positionX posx: CGFloat) -> UIButton! {
        let tagButton = UIButton()
        tagButton.titleLabel?.font = font
        tagButton.backgroundColor = tagBackgroundColor
        tagButton.setTitleColor(tagForegroundColor, forState: UIControlState.Normal)
        tagButton.setTitle(tag, forState: UIControlState.Normal)
        tagButton.addTarget(self, action: "tagButtonDidPushed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var btnFrame: CGRect = tagButton.frame
        btnFrame.origin.x = posx
        btnFrame.origin.y = tagGap + 6.0
        
        let temp: NSString = tag
        btnFrame.size.width = temp.sizeWithAttributes([NSFontAttributeName:font]).width + (tagButton.layer.cornerRadius * 2.0) + 20.0
        btnFrame.size.height = self.frame.size.height - 13.0
        
        tagButton.layer.cornerRadius = btnFrame.size.height * 0.5
        tagButton.frame = CGRectIntegral(btnFrame)
        
        NSLog("btn frame [%s] = %s", tag, NSStringFromCGRect(tagButton.frame))
        
        return tagButton
    }

    private func deleteBackspace() {
        let text: String = tagInputView.text
        if countElements(text) == 0 {
            if readyToDelete {
                if tagsMade.count > 0 {
                    let deletedTag = tagsMade[tagsMade.endIndex - 1]
                    removeTag(deletedTag, animated: true)
                    readyToDelete = false
                }
            } else {
                readyToDelete = true
            }
        }
    }
    
    private func isFinishLetter(letter: String) -> Bool {
        if letter == "\n" {
            return true
        }
        
        if letter == " " {
            if allowToUseSingleSpace && readyToFinishMaking == false {
                readyToFinishMaking = true
                return false
            } else {
                readyToFinishMaking = false
                return true
            }
        } else {
            readyToFinishMaking = false
        }
        return false
    }
    
    private func layoutInputAndScroll() {
        var accumX = posXForObjectNextToLastTagView()
        var inputRect = tagInputView.frame
        inputRect.origin.x = accumX
        inputRect.origin.y = tagGap + 6.0
        inputRect.size.width = widthForInputView(tagString: tagInputView.text)
        inputRect.size.height = self.frame.size.height - 13.0
        
        tagInputView.frame = inputRect
        tagInputView.font = font
        tagInputView.layer.borderColor = tagBackgroundColor.CGColor
        tagInputView.layer.borderWidth = 1.0
        tagInputView.layer.cornerRadius = tagInputView.frame.size.height * 0.5
        tagInputView.backgroundColor = UIColor.clearColor()
        tagInputView.textColor = tagBackgroundColor

        var contentSize = scrollView.contentSize
        contentSize.width = accumX + inputRect.size.width + 20.0
        scrollView.contentSize = contentSize

        setScrollOffsetToMakeInputViewVisible()
    }
    
    private func removeTagView(index: Int, animated: Bool, completion: (finished: Bool) -> Void) {
        if index >= tagViews.count {
            return
        }
        
        let deletedView = tagViews[index]
        deletedView.removeFromSuperview()
        tagViews.removeAtIndex(index)
        
        func layout() {
            var posX: CGFloat = tagGap
            for (idx, view) in enumerate(tagViews) {
                var viewFrame = view.frame
                viewFrame.origin.x = posX
                view.frame = viewFrame
                
                posX += viewFrame.size.width + tagGap
                view.tag = idx
            }
        }
        
        if animated {
            UIView.animateWithDuration(0.25, animations: layout, completion: completion)
        } else {
            layout()
        }
    }
    
    private func posXForObjectNextToLastTagView() -> CGFloat {
        var accumX = tagGap
        
        if tagViews.count > 0 {
            let last = tagViews[tagViews.endIndex - 1]
            accumX = last.frame.origin.x + last.frame.size.width + tagGap
        }
        return accumX
    }
    
    private func setScrollOffsetToMakeInputViewVisible() {
        var inputRect = tagInputView.frame
        var scrollingDelta = (inputRect.origin.x + inputRect.size.width) - (scrollView.contentOffset.x + scrollView.frame.size.width)
        if scrollingDelta > 0 {
            var scrollOffset = scrollView.contentOffset
            scrollOffset.x += scrollingDelta + 40.0
            scrollView.contentOffset = scrollOffset
        }
    }
    
    private func widthForInputView(tagString tag: String) -> CGFloat {
        let temp: NSString = tag
        return max(50.0, temp.sizeWithAttributes([NSFontAttributeName:font]).width + 25.0)
    }
    
    // MARK: UITextViewDelegate
    public func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
        let piece: String = text
        let t: String = textView.text
        
        let pieceCount = countElements(piece)
        let textCount = countElements(t)
        
        if isFinishLetter(piece) {
            if textCount > 0 {
                addTagToLast(t, animated: true)
                textView.text = ""
            }
            if piece == "\n" {
                textView.resignFirstResponder()
            }
            return false
        }
        
        let currentWidth: CGFloat = widthForInputView(tagString: t)
        var newWidth: CGFloat = 0.0
        var newText: String?
        
        if pieceCount == 0 {
            if textCount > 0 {
                let loc = textCount - range.length
                newText = t[0...loc]
            } else {
                deleteBackspace()
                return false
            }
        } else {
            if textCount + pieceCount > maxTagLength {
                return false
            }
            newText = t + piece
        }
        newWidth = widthForInputView(tagString: newText!)
        
        var inputRect = tagInputView.frame
        inputRect.size.width = newWidth
        tagInputView.frame = inputRect
        
        var widthDelta = newWidth - currentWidth
        var contentSize = scrollView.contentSize
        contentSize.width += widthDelta
        scrollView.contentSize = contentSize
        
        setScrollOffsetToMakeInputViewVisible()
        
        return true
    }
    
    public func textViewDidChange(textView: UITextView!) {
        delegate?.tagWriteView?(self, didChangeText: textView.text)
    }
    
    public func textViewDidBeginEditing(textView: UITextView!) {
        delegate?.tagWriteViewDidBeginEditing?(self)
    }
    
    public func textViewDidEndEditing(textView: UITextView!) {
        delegate?.tagWriteViewDidEndEditing?(self)
    }
}


@objc public protocol TagWriteViewDelegate {
    optional func tagWriteViewDidBeginEditing(view: TagWriteView!)
    optional func tagWriteViewDidEndEditing(view: TagWriteView!)
    
    optional func tagWriteView(view: TagWriteView!, didChangeText text: String!)
    optional func tagWriteView(view: TagWriteView!, didMakeTag tag: String!)
    optional func tagWriteView(view: TagWriteView!, didRemoveTag tag: String!)
}


