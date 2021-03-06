//
//  SACChatViewLayout.swift
//  SAChat
//
//  Created by SAGESSE on 26/12/2016.
//  Copyright © 2016-2017 SAGESSE. All rights reserved.
//

import UIKit

@objc open class SACChatViewLayout: UICollectionViewFlowLayout {
    
    public override init() {
        super.init()
        _commonInit()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _commonInit()
    }
    
    open override class var layoutAttributesClass: AnyClass {
        return SACChatViewLayoutAttributes.self
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        if let attributes = attributes as? SACChatViewLayoutAttributes {
            attributes.info = layoutAttributesInfoForItem(at: indexPath)
        }
        return attributes
    }
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let arr = super.layoutAttributesForElements(in: rect)
        arr?.forEach({
            guard let attributes = $0 as? SACChatViewLayoutAttributes else {
                return
            }
            attributes.info = layoutAttributesInfoForItem(at: attributes.indexPath)
        })
        return arr
    }
    
    open func layoutAttributesInfoForItem(at indexPath: IndexPath) -> SACChatViewLayoutAttributesInfo? {
        guard let collectionView = collectionView, let delegate = collectionView.delegate as? SACChatViewLayoutDelegate else {
            return nil
        }
        let size = CGSize(width: collectionView.frame.width, height: .greatestFiniteMagnitude)
        if let info = _allLayoutAttributesInfo[indexPath] {
            //logger.trace("\(indexPath) - hit cache - \(info.layoutedBoxRect(with: .all))")
            return info
        }
        let message = delegate.collectionView(collectionView, layout: self, itemAt: indexPath)
        let options = message.options
        
        var allRect: CGRect = .zero
        var allBoxRect: CGRect = .zero
        
        var cardRect: CGRect = .zero
        var cardBoxRect: CGRect = .zero
        
        var avatarRect: CGRect = .zero
        var avatarBoxRect: CGRect = .zero
        
        var contentRect: CGRect = .zero
        var contentBoxRect: CGRect = .zero
        
        // 计算的时候以左对齐为基准
        
        // +---------------------------------------+ r0
        // |+---------------------------------+ r1 |
        // ||+---+ <NAME>                     |    |
        // ||| A | +---------------------\ r4 |    |
        // ||+---+ |+---------------+ r5 |    |    |
        // ||      ||    CONTENT    |    |    |    |
        // ||      |+---------------+    |    |    |
        // ||      \---------------------/    |    |
        // |+---------------------------------+    |
        // +---------------------------------------+
        
        let edg0 = _inset(with: options.style, for: .all)
        var r0 = CGRect(x: 0, y: 0, width: size.width, height: .greatestFiniteMagnitude)
        var r1 = UIEdgeInsetsInsetRect(r0, edg0)
        
        var x1 = r1.minX
        var y1 = r1.minY
        var x2 = r1.maxX
        var y2 = r1.maxY
        
        // add avatar if needed
        if options.showsAvatar {
            let edg = _inset(with: options.style, for: .avatar)
            let size = _size(with: options.style, for: .avatar)
                //layoutSize(with: .avatar, size: .init(width: x2 - x1, height: y2 - y1))
            
            let box = CGRect(x: x1, y: y1, width: edg.left + size.width + edg.right, height: edg.top + size.height + edg.bottom)
            let rect = UIEdgeInsetsInsetRect(box, edg)
            
            avatarRect = rect
            avatarBoxRect = box
            
            x1 = box.maxX
        }
        // add card if needed
        if options.showsCard {
            let edg = _inset(with: options.style, for: .card)
            let size = _size(with: options.style, for: .card)
            
            let box = CGRect(x: x1, y: y1, width: x2 - x1, height: edg.top + size.height + edg.bottom)
            let rect = UIEdgeInsetsInsetRect(box, edg)
            
            cardRect = rect
            cardBoxRect = box
            
            y1 = box.maxY
        }
        // add content
        if true {
            let edg0 = _inset(with: options.style, for: .content)
            let edg1 = message.content.layoutMargins
            //
            let edg = UIEdgeInsetsMake(edg0.top + edg1.top, edg0.left + edg1.left, edg0.bottom + edg1.bottom, edg0.right + edg1.right)
            
            var box = CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
            var rect = UIEdgeInsetsInsetRect(box, edg)
            
            // calc content size
            let size = message.content.sizeThatFits(rect.size)
            
            // restore offset
            box.size.width = edg.left + size.width + edg.right
            box.size.height = edg.top + size.height + edg.bottom
            rect.size.width = size.width
            rect.size.height = size.height
            
            contentRect = rect
            contentBoxRect = box
            
            x1 = box.maxX
            y1 = box.maxY
        }
        // adjust
        r1.size.width = x1 - r1.minX
        r1.size.height = y1 - r1.minY
        r0.size.width = x1
        r0.size.height = y1 + edg0.bottom
        
        allRect = r1
        allBoxRect = r0
        
        // algin
        switch options.alignment {
        case .right:
            // to right
            allRect.origin.x = size.width - allRect.maxX
            allBoxRect.origin.x = size.width - allBoxRect.maxX
            
            cardRect.origin.x = size.width - cardRect.maxX
            cardBoxRect.origin.x = size.width - cardBoxRect.maxX
            
            avatarRect.origin.x = size.width - avatarRect.maxX
            avatarBoxRect.origin.x = size.width - avatarBoxRect.maxX
            
            contentRect.origin.x = size.width - contentRect.maxX
            contentBoxRect.origin.x = size.width - contentBoxRect.maxX
            
        case .center:
            // to center
            allRect.origin.x = (size.width - allRect.width) / 2
            allBoxRect.origin.x = (size.width - allBoxRect.width) / 2
            
            contentRect.origin.x = (size.width - contentRect.width) / 2
            contentBoxRect.origin.x = (size.width - contentBoxRect.width) / 2
            
        case .left:
            // to left, nothing doing
            break
        }
        // save
        let rects: [SACChatViewLayoutItem: CGRect] = [
            .all: allRect,
            .card: cardRect,
            .avatar: avatarRect,
            .content: contentRect
        ]
        let boxRects: [SACChatViewLayoutItem: CGRect] = [
            .all: allBoxRect,
            .card: cardBoxRect,
            .avatar: avatarBoxRect,
            .content: contentBoxRect
        ]
        let info = SACChatViewLayoutAttributesInfo(message: message, size: size, rects: rects, boxRects: boxRects)
        _allLayoutAttributesInfo[indexPath] = info
        logger.trace("\(indexPath) - calc - \(info.layoutedBoxRect(with: .all))")
        return info
    }
    
    private func _size(with style: SACMessageStyle, for item: SACChatViewLayoutItem) -> CGSize {
        let key = "\(style.rawValue)-\(item.rawValue)"
        if let size = _cachedAllLayoutSize[key] {
            return size // hit cache
        }
        var size: CGSize?
        if let collectionView = collectionView, let delegate = collectionView.delegate as? SACChatViewLayoutDelegate {
            switch item {
            case .all: break
            case .card: size = delegate.collectionView?(collectionView, layout: self, sizeForItemCardOf: style)
            case .avatar: size = delegate.collectionView?(collectionView, layout: self, sizeForItemAvatarOf: style)
            case .content: break
            }
        }
        _cachedAllLayoutSize[key] = size ?? .zero
        return size ?? .zero
    }
    private func _inset(with style: SACMessageStyle, for item: SACChatViewLayoutItem) -> UIEdgeInsets {
        let key = "\(style.rawValue)-\(item.rawValue)"
        if let edg = _cachedAllLayoutInset[key] {
            return edg // hit cache
        }
        var edg: UIEdgeInsets?
        if let collectionView = collectionView, let delegate = collectionView.delegate as? SACChatViewLayoutDelegate {
            switch item {
            case .all: edg = delegate.collectionView?(collectionView, layout: self, insetForItemOf: style)
            case .card: edg = delegate.collectionView?(collectionView, layout: self, insetForItemCardOf: style)
            case .avatar: edg = delegate.collectionView?(collectionView, layout: self, insetForItemAvatarOf: style)
            case .content: edg = delegate.collectionView?(collectionView, layout: self, insetForItemContentOf: style)
            }
        }
        _cachedAllLayoutInset[key] = edg ?? .zero
        return edg ?? .zero
    }
    
    private func _commonInit() {
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
    }
    
    private lazy var _cachedAllLayoutSize: [String: CGSize] = [:]
    private lazy var _cachedAllLayoutInset: [String: UIEdgeInsets] = [:]
    
    private lazy var _allLayoutAttributesInfo: [IndexPath: SACChatViewLayoutAttributesInfo] = [:]
}

@objc public protocol SACChatViewLayoutDelegate: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, itemAt indexPath: IndexPath) -> SACMessageType
    
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemCardOf style: SACMessageStyle) -> CGSize
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAvatarOf style: SACMessageStyle) -> CGSize
    
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForItemOf style: SACMessageStyle) -> UIEdgeInsets
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForItemCardOf style: SACMessageStyle) -> UIEdgeInsets
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForItemAvatarOf style: SACMessageStyle) -> UIEdgeInsets
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForItemContentOf style: SACMessageStyle) -> UIEdgeInsets
}
