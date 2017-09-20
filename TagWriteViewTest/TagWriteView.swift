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

let CharacterForDetectingBackspaceDeletion = "\u{200B}"

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
    
    public var tags: [String] {
        return tagsMade
    }
    
    public var maxTagLength = 20   // maximum length of a tag
    public var tagGap: CGFloat = 4.0   // a gap between tags
    public var allowToUseSingleSpace = false   // if true, space character is allowed to use
    public var insetForTag = UIEdgeInsets.zero  // right inset is not avaliable. a tag has same length for horizontal margins(left, right) based on left value
    public var minimumWidthOfTag: CGFloat = 50.0
    public var placeHolderForInput: NSAttributedString! {
        didSet {
            tagInputView.attributedPlaceholder = placeHolderForInput
        }
    }
    
    public var focusOnAddTag: Bool = false {
        didSet {
            if focusOnAddTag {
                tagInputView.becomeFirstResponder()
            } else {
                tagInputView.resignFirstResponder()
            }
        }
    }
    
    public weak var delegate: TagWriteViewDelegate? = nil
    
    public var scrollView: UIScrollView!
    public var inputBaseView: UIView!
    public var tagInputView: UITextField!
    public var deleteButton: UIButton!
    
    // MARK: Private Properties
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
            newFrame.size.height = self.bounds.size.height - (insetForTag.top + insetForTag.bottom)
            newFrame.origin.y = insetForTag.top
            btn.frame = newFrame
            
            btn.layer.cornerRadius = newFrame.size.height * 0.5
        }
        
        layoutInputAndScroll()
    }
    
    // MARK: Interfaces
    public func clear() {
        tagInputView.text = "\(CharacterForDetectingBackspaceDeletion)"
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
        let newTag = tag.trimmingCharacters(in: CharacterSet(charactersIn: " \n\t\(CharacterForDetectingBackspaceDeletion)"))
        if newTag.characters.count == 0 {
            return
        }
        
        for t in tagsMade {
            if newTag == t {
                return
            }
        }
        
        tagsMade.append(newTag)
        
        tagInputView.text = "\(CharacterForDetectingBackspaceDeletion)"
        addTagViewToLast(newTag, animated: animated)
        setNeedsLayout()
        delegate?.tagWriteView?(view: self, didMakeTag: newTag)
    }
    
    public func removeTag(_ tag: String, animated: Bool) {
        var foundIndex = -1
        for (idx, value) in tagsMade.enumerated() {
            if tag == value {
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
    @objc func tagButtonDidPushed(sender: UIButton) {
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
            if deleteButton.superview != nil {
                deleteButton.removeFromSuperview()
            }
            scrollView.addSubview(deleteButton)
            deleteButton.isHidden = false
        }
    }
    
    @objc func deleteButtonDidPush(sender: Any) {
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
        scrollView.scrollsToTop = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(scrollView)
        scrollView.applyMarginConstraint(margin: UIEdgeInsets.zero)
        
        inputBaseView = UIView()
        inputBaseView.backgroundColor = UIColor.clear
        scrollView.addSubview(inputBaseView)
        
        tagInputView = UITextField(frame: inputBaseView.bounds)
        tagInputView.delegate = self
        tagInputView.autocorrectionType = UITextAutocorrectionType.no
        tagInputView.returnKeyType = UIReturnKeyType.done
        tagInputView.autoresizingMask = UIViewAutoresizing.flexibleWidth
        inputBaseView.addSubview(tagInputView)
        
        deleteButton = UIButton(frame: CGRect(x: 0, y: 0, width: 17, height: 17))
        deleteButton.backgroundColor = .white
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
        btnFrame.size.width = temp.size(withAttributes: [NSAttributedStringKey.font:font]).width + (tagButton.layer.cornerRadius * 2.0) + insetForTag.left + insetForTag.left
        //        btnFrame.size.height = self.frame.size.height - 13.0
        
        tagButton.layer.cornerRadius = btnFrame.size.height * 0.5
        tagButton.frame = btnFrame.integral
        
        return tagButton
    }
    
    fileprivate func deleteBackspace() {
        let text: String = tagInputView.text!
        if text.characters.count == 1 {
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
        inputRect.origin.y = insetForTag.top
        inputRect.size.width = widthForInputView(tagString: tagInputView.text!) + insetForTag.left + insetForTag.left
        inputRect.size.height = self.bounds.height - (insetForTag.top + insetForTag.bottom)
        
        inputBaseView.frame = inputRect
        inputBaseView.layer.borderColor = tagBackgroundColor.cgColor
        inputBaseView.layer.borderWidth = 1.0
        inputBaseView.layer.cornerRadius = inputBaseView.bounds.height * 0.5
        
        let tagTextFieldRect = CGRect(x: insetForTag.left,
                                      y: font.descender * 0.2,
                                      width: widthForInputView(tagString: tagInputView.text!),
                                      height: inputRect.size.height)
        tagInputView.frame = tagTextFieldRect
        
        var contentSize = scrollView.contentSize
        contentSize.width = accumX + inputRect.size.width + 20.0
        scrollView.contentSize = contentSize
        
        setScrollOffsetToMakeInputViewVisible()
    }
    
    fileprivate func removeTagView(at index: Int, animated: Bool, completion: @escaping ((_ finished: Bool) -> Void)) {
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
        return max(minimumWidthOfTag, temp.size(withAttributes: [NSAttributedStringKey.font:font]).width + 25.0)
    }
    
}

// MARK: UITextViewDelegate
extension TagWriteView: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let piece: String = string
        let t: String = textField.text!
        
        let pieceCount = piece.characters.count
        let textCount = t.characters.count
        
        if isFinishLetter(piece) {
            if textCount > 0 {
                addTagToLast(t, animated: true)
                textField.text = "\(CharacterForDetectingBackspaceDeletion)"
            }
            if piece == "\n" {
                textField.resignFirstResponder()
            }
            return false
        }
        
        let expected = NSString(string: t).replacingCharacters(in: range, with: piece)
        if let delegate = delegate, delegate.tagWriteView?(view: self, shouldChangeText: expected) == false {
            return false
        }
        
        let currentWidth: CGFloat = widthForInputView(tagString: t)
        var newWidth: CGFloat = 0.0
        var newText: String?
        
        if pieceCount == 0 {
            if textCount > 1 {
                let loc = textCount - range.length
                let startIndex = t.startIndex
                let endIndex = t.index(t.startIndex, offsetBy: loc)
                newText = String(t[startIndex...endIndex])
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
        
        delegate?.tagWriteView?(view: self, didChangeText: textField.text)
        
        return true
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.tagWriteViewDidBeginEditing?(view: self)
        if tagInputView.text!.characters.count == 0 {
            tagInputView.text = CharacterForDetectingBackspaceDeletion
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.tagWriteViewDidEndEditing?(view: self)
        if tagInputView.text! == CharacterForDetectingBackspaceDeletion {
            tagInputView.text = ""
        }
    }
}

@objc public protocol TagWriteViewDelegate {
    @objc optional func tagWriteViewDidBeginEditing(view: TagWriteView!)
    @objc optional func tagWriteViewDidEndEditing(view: TagWriteView!)
    
    @objc optional func tagWriteView(view: TagWriteView!, shouldChangeText text: String!) -> Bool
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
