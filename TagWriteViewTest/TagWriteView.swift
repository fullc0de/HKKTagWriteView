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
{
    
    // MARK: Public Properties
    public var font: UIFont = UIFont.systemFont(ofSize: 14.0) {
        didSet {
            for btn in tagViews {
                btn.titleLabel?.font = font
            }
        }
    }
    
    public var tagBackgroundColor: UIColor = UIColor.darkGray {
        didSet {
            for btn in tagViews {
                btn.backgroundColor = tagBackgroundColor
            }
            tagInputView.layer.borderColor = tagBackgroundColor.cgColor
            tagInputView.textColor = tagBackgroundColor
        }
    }
    
    public var tagForegroundColor: UIColor = UIColor.white {
        didSet {
            for btn in tagViews {
                btn.setTitleColor(tagForegroundColor, for: .normal)
            }
        }
    }
    
    public var sizeForDeleteButton = CGRect(x: 0, y: 0, width: 17, height: 17) {
        didSet {
            deleteButton.frame = sizeForDeleteButton
        }
    }
    
    public var backgroundColorForDeleteButton = UIColor.white {
        didSet {
            if deleteButton != nil {
                deleteButton.backgroundColor = backgroundColorForDeleteButton
            }
        }
    }
    
    
    public var tags: [String] {
        return tagsMade
    }
    
    public var maxTagLength = 20   // maximum length of a tag
    public var tagGap: CGFloat = 4.0   // a gap between tags
    public var allowToUseSingleSpace = false   // if true, space character is allowed to use
    public var verticalInsetForTag = UIEdgeInsets.zero  // 'top' and 'bottom' properties are only available. set vertical margin to each tags.
    
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
    fileprivate var scrollView: UIScrollView!
    fileprivate var inputBaseView: UIView!
    fileprivate var tagInputView: UITextView!
    fileprivate var deleteButton: UIButton!
    
    fileprivate var tagViews = [UIButton]()
    fileprivate var tagsMade = [String]()
    
    fileprivate var readyToDelete = false
    fileprivate var readyToFinishMaking = false
    
    
    // MARK: Initializers
    required public init?(coder aDecoder: NSCoder) {
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
    public func clear() {
        tagInputView.text = ""
        tagsMade.removeAll(keepingCapacity: false)
        rearrangeSubViews()
    }
    
    public func setTextToInputSlot(text: String) {
        tagInputView.text = text
    }
    
    public func addTags(_ tags: [String]) {
        for tag in tags {
            let result = tagsMade.filter({$0 == tag})
            if result.count == 0 {
                tagsMade.append(tag)
            }
        }
        
        rearrangeSubViews()
    }
    
    public func removeTags(_ tags: [String]) {
        var pickedIndexes = [Int]()
        for tag in tags {
            for (idx, value) in tagsMade.enumerated() {
                if value == tag {
                    pickedIndexes.append(idx)
                }
            }
        }
        
        for idx in pickedIndexes {
            tagsMade.remove(at: idx)
        }
        
        rearrangeSubViews()
    }
    
    public func addTagToLast(_ tag: String, animated: Bool) {
        let newTag = tag.trimmingCharacters(in: .whitespaces)
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
        delegate?.tagWriteView?(view: self, didChangeText: newTag)
    }
    
    public func removeTag(_ tag: String, animated: Bool) {
        var foundIndex = -1
        for (idx, value) in tagsMade.enumerated() {
            if tag == value {
                print("FOUND!")
                foundIndex = idx
            }
        }
        
        if foundIndex == -1 {
            return
        }
        
        tagsMade.remove(at: foundIndex)
        removeTagView(at: foundIndex, animated: animated, completion: { (_ finished: Bool) -> Void in
            self.setNeedsLayout()
        })
        
        delegate?.tagWriteView?(view: self, didRemoveTag: tag)
    }
    
    public func setDeleteButtonBackgroundImage(_ image: UIImage?, state: UIControlState) {
        deleteButton.setBackgroundImage(image, for: state)
    }
    
    // MARK: UI Actions
    func tagButtonDidPushed(sender: UIButton) {
        let btn = sender
        
        if deleteButton.isHidden == false && btn.tag == deleteButton.tag {
            deleteButton.isHidden = true
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
            deleteButton.isHidden = false
        }
    }
    
    func deleteButtonDidPush(sender: Any) {
        if tagsMade.count <= deleteButton.tag {
            return
        }
        
        deleteButton.isHidden = true
        deleteButton.removeFromSuperview()
        
        let tag = tagsMade[deleteButton.tag]
        removeTag(tag, animated: true)
    }
    
    // MARK: Internals
    private func initControls() {
        scrollView = UIScrollView(frame: self.bounds)
        scrollView.backgroundColor = UIColor.clear
        scrollView.scrollsToTop = false;
        scrollView.showsVerticalScrollIndicator = false;
        scrollView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(scrollView)
        scrollView.applyMarginConstraint(margin: UIEdgeInsets.zero)
        
        inputBaseView = UIView()
        inputBaseView.backgroundColor = UIColor.clear
        scrollView.addSubview(inputBaseView)
        
        tagInputView = UITextView(frame: inputBaseView.bounds)
        tagInputView.delegate = self
        tagInputView.autocorrectionType = UITextAutocorrectionType.no
        tagInputView.returnKeyType = UIReturnKeyType.done
        tagInputView.scrollsToTop = false
        tagInputView.autoresizingMask = UIViewAutoresizing.flexibleWidth
        inputBaseView.addSubview(tagInputView)
        
        deleteButton = UIButton(frame: sizeForDeleteButton)
        deleteButton.backgroundColor = backgroundColorForDeleteButton
        deleteButton.addTarget(self, action: #selector(self.deleteButtonDidPush(sender:)), for: .touchUpInside)
        deleteButton.isHidden = true;
    }
    
    private func addTagViewToLast(_ newTag: String, animated: Bool) {
        let posX = posXForObjectNextToLastTagView()
        let tagBtn = createTagButton(tagName: newTag, positionX: posX)
        tagBtn.tag = tagViews.count
        tagViews.append(tagBtn)
        scrollView.addSubview(tagBtn)
        
        if animated {
            tagBtn.alpha = 0.0
            UIView.animate(withDuration: 0.25, animations: {tagBtn.alpha = 1.0})
        }
    }
    
    private func rearrangeSubViews() {
        var accumX = tagGap
        var newTagButtons: [UIButton] = Array()
        
        newTagButtons.reserveCapacity(tagsMade.count)
        for (index, tag) in tagsMade.enumerated() {
            let tagButton = self.createTagButton(tagName: tag, positionX: accumX)
            newTagButtons.append(tagButton)
            tagButton.tag = index
            accumX += tagButton.frame.size.width + tagGap
            scrollView.addSubview(tagButton)
        }
        
        for oldTagButton in tagViews {
            oldTagButton.removeFromSuperview()
        }
        tagViews.removeAll(keepingCapacity: false)
        tagViews += newTagButtons
        
        setNeedsLayout();
    }
    
    private func createTagButton(tagName tag: String, positionX posx: CGFloat) -> UIButton {
        let tagButton = UIButton()
        tagButton.titleLabel?.font = font
        tagButton.backgroundColor = tagBackgroundColor
        tagButton.setTitleColor(tagForegroundColor, for: UIControlState.normal)
        tagButton.setTitle(tag, for: UIControlState.normal)
        tagButton.addTarget(self, action: #selector(self.tagButtonDidPushed(sender:)), for: .touchUpInside)
        
        var btnFrame: CGRect = tagButton.frame
        btnFrame.origin.x = posx
        
        let temp = tag as NSString
        btnFrame.size.width = temp.size(attributes: [NSFontAttributeName:font]).width + (tagButton.layer.cornerRadius * 2.0) + 20.0
        //        btnFrame.size.height = self.frame.size.height - 13.0
        
        tagButton.layer.cornerRadius = btnFrame.size.height * 0.5
        tagButton.frame = btnFrame.integral
        
        return tagButton
    }
    
    fileprivate func deleteBackspace() {
        let text: String = tagInputView.text
        if text.characters.count == 0 {
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
    
    fileprivate func isFinishLetter(_ letter: String) -> Bool {
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
    
    fileprivate func layoutInputAndScroll() {
        tagInputView.font = font
        tagInputView.backgroundColor = UIColor.clear
        tagInputView.textColor = tagBackgroundColor
        
        let accumX = posXForObjectNextToLastTagView()
        var inputRect = inputBaseView.frame
        inputRect.origin.x = accumX
        inputRect.origin.y = verticalInsetForTag.top
        inputRect.size.width = widthForInputView(tagString: tagInputView.text)
        inputRect.size.height = self.bounds.height - (verticalInsetForTag.top + verticalInsetForTag.bottom)
        
        inputBaseView.frame = inputRect
        inputBaseView.layer.borderColor = tagBackgroundColor.cgColor
        inputBaseView.layer.borderWidth = 1.0
        inputBaseView.layer.cornerRadius = inputBaseView.bounds.height * 0.5
        
        tagInputView.frame = inputBaseView.bounds
        tagInputView.frame.origin.y = font.descender * 0.5 // It's a nagetive number
        tagInputView.frame.size.height = self.bounds.height - verticalInsetForTag.top
        
        var contentSize = scrollView.contentSize
        contentSize.width = accumX + inputRect.size.width + 20.0
        scrollView.contentSize = contentSize
        
        setScrollOffsetToMakeInputViewVisible()
    }
    
    fileprivate func removeTagView(at index: Int, animated: Bool, completion: ((_ finished: Bool) -> Void)) {
        if index >= tagViews.count {
            return
        }
        
        let deletedView = tagViews[index]
        deletedView.removeFromSuperview()
        tagViews.remove(at: index)
        
        func layout() {
            var posX: CGFloat = tagGap
            for (idx, view) in tagViews.enumerated() {
                var viewFrame = view.frame
                viewFrame.origin.x = posX
                view.frame = viewFrame
                
                posX += viewFrame.size.width + tagGap
                view.tag = idx
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: layout, completion: completion)
        } else {
            layout()
        }
    }
    
    fileprivate func posXForObjectNextToLastTagView() -> CGFloat {
        var accumX = tagGap
        
        if tagViews.count > 0 {
            let last = tagViews[tagViews.endIndex - 1]
            accumX = last.frame.origin.x + last.frame.size.width + tagGap
        }
        return accumX
    }
    
    fileprivate func setScrollOffsetToMakeInputViewVisible() {
        let inputRect = inputBaseView.frame
        let scrollingDelta = (inputRect.origin.x + inputRect.size.width) - (scrollView.contentOffset.x + scrollView.frame.size.width)
        if scrollingDelta > 0 {
            var scrollOffset = scrollView.contentOffset
            scrollOffset.x += scrollingDelta + 40.0
            scrollView.contentOffset = scrollOffset
        }
    }
    
    fileprivate func widthForInputView(tagString tag: String) -> CGFloat {
        let temp = tag as NSString
        return max(50.0, temp.size(attributes: [NSFontAttributeName:font]).width + 25.0)
    }
    
}

// MARK: UITextViewDelegate
extension TagWriteView: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let piece: String = text
        let t: String = textView.text
        
        let pieceCount = piece.characters.count
        let textCount = t.characters.count
        
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
                let startIndex = t.startIndex
                let endIndex = t.index(t.startIndex, offsetBy: loc)
                newText = t[startIndex...endIndex]
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
        
        let widthDelta = newWidth - currentWidth
        var contentSize = scrollView.contentSize
        contentSize.width += widthDelta
        scrollView.contentSize = contentSize
        
        setScrollOffsetToMakeInputViewVisible()
        
        return true
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        delegate?.tagWriteView?(view: self, didChangeText: textView.text)
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.tagWriteViewDidBeginEditing?(view: self)
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.tagWriteViewDidEndEditing?(view: self)
    }
}

@objc public protocol TagWriteViewDelegate {
    @objc optional func tagWriteViewDidBeginEditing(view: TagWriteView!)
    @objc optional func tagWriteViewDidEndEditing(view: TagWriteView!)
    
    @objc optional func tagWriteView(view: TagWriteView!, didChangeText text: String!)
    @objc optional func tagWriteView(view: TagWriteView!, didMakeTag tag: String!)
    @objc optional func tagWriteView(view: TagWriteView!, didRemoveTag tag: String!)
}


extension UIView {
    func applyMarginConstraint(margin: UIEdgeInsets) {
        if self.superview == nil {
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let view = ["view":self]
        let metrics = ["left":margin.left, "right":margin.right,"top":margin.top, "bottom":margin.bottom]
        self.superview!.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-left-[view]-right-|", options: [], metrics: metrics, views: view))
        self.superview!.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[view]-bottom-|", options: [], metrics: metrics, views: view))
    }
}
