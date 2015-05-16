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

public class TagWriteView : UIView
    , UITextViewDelegate
{
    
    // MARK: Public Properties
    var font: UIFont = UIFont.systemFontOfSize(14.0) {
    didSet {
        for btn in tagViews {
            btn.titleLabel?.font = font
        }
    }
    }
    
    var tagBackgroundColor: UIColor = UIColor.darkGrayColor() {
    didSet {
        for btn in tagViews {
            btn.backgroundColor = tagBackgroundColor
        }
        tagInputView.layer.borderColor = tagBackgroundColor.CGColor
        tagInputView.textColor = tagBackgroundColor
    }
    }
    
    var tagForegroundColor: UIColor = UIColor.whiteColor() {
    didSet {
        for btn in tagViews {
            btn.setTitleColor(tagForegroundColor, forState: UIControlState.Normal)
        }
    }
    }
    
    var sizeForDeleteButton = CGRectMake(0, 0, 17, 17) {
        didSet {
            deleteButton.frame = sizeForDeleteButton
        }
    }
    
    var backgroundColorForDeleteButton = UIColor.whiteColor() {
        didSet {
            if deleteButton != nil {
                deleteButton.backgroundColor = backgroundColorForDeleteButton
            }
        }
    }
    
    
    var tags: [String] {
        return tagsMade
    }
    
    var maxTagLength = 20   // maximum length of a tag
    var tagGap: CGFloat = 4.0   // a gap between tags
    var allowToUseSingleSpace = false   // if true, space character is allowed to use
    var verticalInsetForTag = UIEdgeInsetsZero  // 'top' and 'bottom' properties are only available. set vertical margin to each tags.
    
    var focusOnAddTag: Bool = false {
    didSet {
        if focusOnAddTag {
            tagInputView.becomeFirstResponder()
        } else {
            tagInputView.resignFirstResponder()
        }
    }
    }
    
    var delegate: TagWriteViewDelegate?
    
    
    // MARK: Private Properties
    private var scrollView: UIScrollView!
    private var inputBaseView: UIView!
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
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        for btn in tagViews {
            var newFrame = btn.frame
            newFrame.size.height = self.bounds.size.height - (verticalInsetForTag.top + verticalInsetForTag.bottom)
            newFrame.origin.y = verticalInsetForTag.top
            btn.frame = newFrame
            
            btn.layer.cornerRadius = newFrame.size.height * 0.5
        }
        
        layoutInputAndScroll()
    }
    
    // MARK: Interfaces
    func clear() {
        tagInputView.text = ""
        tagsMade.removeAll(keepCapacity: false)
        rearrangeSubViews()
    }
    
    func setTextToInputSlot(text: String) {
        tagInputView.text = text
    }
    
    func addTags(tags: [String]) {
        for tag in tags {
            let result = tagsMade.filter({$0 == tag})
            if result.count == 0 {
                tagsMade.append(tag)
            }
        }
        
        rearrangeSubViews()
    }
    
    func removeTags(tags: [String]) {
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
    
    func addTagToLast(tag: String, animated: Bool) {
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
        setNeedsLayout()
        delegate?.tagWriteView?(self, didChangeText: newTag)
    }

    func removeTag(tag: String, animated: Bool) {
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
        removeTagView(foundIndex, animated: animated, completion: { (finished: Bool) -> Void in
            self.setNeedsLayout()
        })
        
        delegate?.tagWriteView?(self, didRemoveTag: tag)
    }

    func setDeleteButtonBackgroundImage(image: UIImage?, state: UIControlState) {
        deleteButton.setBackgroundImage(image, forState: state)
    }
    
    // MARK: UI Actions
    func tagButtonDidPushed(sender: AnyObject!) {
        let btn = sender as! UIButton

        if deleteButton.hidden == false && btn.tag == deleteButton.tag {
            deleteButton.hidden = true
            deleteButton.removeFromSuperview()
        } else {
            var center = btn.center
            center.x += (btn.bounds.width * 0.5) - (deleteButton.bounds.width * 0.2)
            center.y -= (btn.bounds.height * 0.5) - (deleteButton.bounds.height * 0.2)
            deleteButton.center = center
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
        scrollView.applyMarginConstraint(margin: UIEdgeInsetsZero)
        
        inputBaseView = UIView()
        inputBaseView.backgroundColor = UIColor.greenColor()
        scrollView.addSubview(inputBaseView)
        
        tagInputView = UITextView(frame: inputBaseView.bounds)
        tagInputView.delegate = self
        tagInputView.autocorrectionType = UITextAutocorrectionType.No
        tagInputView.returnKeyType = UIReturnKeyType.Done
        tagInputView.scrollsToTop = false
        tagInputView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        inputBaseView.addSubview(tagInputView)
        
        deleteButton = UIButton(frame: sizeForDeleteButton)
        deleteButton.backgroundColor = backgroundColorForDeleteButton
        deleteButton.addTarget(self, action: "deleteButtonDidPush:", forControlEvents: UIControlEvents.TouchUpInside)
        deleteButton.hidden = true;
    }
    
    private func addTagViewToLast(newTag: String, animated: Bool) {
        var posX = posXForObjectNextToLastTagView()
        let tagBtn = createTagButton(tagName: newTag, positionX: posX)
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
            let tagButton = self.createTagButton(tagName: tag, positionX: accumX)
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
        
        setNeedsLayout();
    }
    
    private func createTagButton(tagName tag: String, positionX posx: CGFloat) -> UIButton! {
        let tagButton = UIButton()
        tagButton.titleLabel?.font = font
        tagButton.backgroundColor = tagBackgroundColor
        tagButton.setTitleColor(tagForegroundColor, forState: UIControlState.Normal)
        tagButton.setTitle(tag, forState: UIControlState.Normal)
        tagButton.addTarget(self, action: "tagButtonDidPushed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var btnFrame: CGRect = tagButton.frame
        btnFrame.origin.x = posx
        
        let temp: NSString = tag
        btnFrame.size.width = temp.sizeWithAttributes([NSFontAttributeName:font]).width + (tagButton.layer.cornerRadius * 2.0) + 20.0
//        btnFrame.size.height = self.frame.size.height - 13.0
        
        tagButton.layer.cornerRadius = btnFrame.size.height * 0.5
        tagButton.frame = CGRectIntegral(btnFrame)
        
        return tagButton
    }

    private func deleteBackspace() {
        let text: String = tagInputView.text
        if count(text) == 0 {
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
        tagInputView.font = font
        tagInputView.backgroundColor = UIColor.clearColor()
        tagInputView.textColor = tagBackgroundColor
        
        var accumX = posXForObjectNextToLastTagView()
        var inputRect = inputBaseView.frame
        inputRect.origin.x = accumX
        inputRect.origin.y = verticalInsetForTag.top
        inputRect.size.width = widthForInputView(tagString: tagInputView.text)
        inputRect.size.height = self.bounds.height - (verticalInsetForTag.top + verticalInsetForTag.bottom)

        inputBaseView.frame = inputRect
        inputBaseView.layer.borderColor = tagBackgroundColor.CGColor
        inputBaseView.layer.borderWidth = 1.0
        inputBaseView.layer.cornerRadius = inputBaseView.frame.size.height * 0.5

        var inputFieldRect = inputBaseView.bounds
        inputFieldRect.size.height = 20.0
        inputFieldRect.origin.y = (inputBaseView.bounds.height - 20.0) * 0.5
        tagInputView.frame = inputFieldRect
        
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
        var inputRect = inputBaseView.frame
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
}

extension TagWriteView: UITextViewDelegate {
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let piece: String = text
        let t: String = textView.text
        
        let pieceCount = count(piece)
        let textCount = count(t)
        
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
        
        var inputRect = inputBaseView.frame
        inputRect.size.width = newWidth
        inputBaseView.frame = inputRect
        
        var widthDelta = newWidth - currentWidth
        var contentSize = scrollView.contentSize
        contentSize.width += widthDelta
        scrollView.contentSize = contentSize
        
        setScrollOffsetToMakeInputViewVisible()
        
        return true
    }
    
    public func textViewDidChange(textView: UITextView) {
        delegate?.tagWriteView?(self, didChangeText: textView.text)
    }
    
    public func textViewDidBeginEditing(textView: UITextView) {
        delegate?.tagWriteViewDidBeginEditing?(self)
    }
    
    public func textViewDidEndEditing(textView: UITextView) {
        delegate?.tagWriteViewDidEndEditing?(self)
    }
}

@objc protocol TagWriteViewDelegate {
    optional func tagWriteViewDidBeginEditing(view: TagWriteView!)
    optional func tagWriteViewDidEndEditing(view: TagWriteView!)
    
    optional func tagWriteView(view: TagWriteView!, didChangeText text: String!)
    optional func tagWriteView(view: TagWriteView!, didMakeTag tag: String!)
    optional func tagWriteView(view: TagWriteView!, didRemoveTag tag: String!)
}


extension UIView {
    func applyMarginConstraint(#margin: UIEdgeInsets) {
        if self.superview == nil {
            return
        }
        
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let view = ["view":self]
        let metrics = ["left":margin.left, "right":margin.right,"top":margin.top, "bottom":margin.bottom]
        self.superview!.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-left-[view]-right-|", options: nil, metrics: metrics, views: view))
        self.superview!.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-top-[view]-bottom-|", options: nil, metrics: metrics, views: view))
    }
}

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
