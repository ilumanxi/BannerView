//
//  BannerView.swift
//  BannerView
//
//  Created by Tanfanfan on 16/6/7.
//  Copyright © 2016年 Tanfanfan. All rights reserved.
//

import UIKit


@IBDesignable

public extension UIView {
    
    
}

public class BannerView: UIView {

    
    private(set) lazy var pageControl: UIPageControl = {
       let pageControl =  UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    
   private class BannerViewCell: UICollectionViewCell {
    
        lazy var imageView: UIImageView = {
            let view = UIImageView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
    
        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
        }
    
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            initUI()
        }
    
        private func initUI() {
            let views = ["imageView":imageView]
            addSubview(imageView)
            let vhConstraints = [NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: [], metrics: nil, views: views),NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|", options: [], metrics: nil, views: views)].flatMap { (constraints) -> [NSLayoutConstraint] in
                return constraints
            }
            NSLayoutConstraint.activateConstraints(vhConstraints)
            
        }
        
    }
   
    
    private static let reuseIdentifier = String(BannerViewCell)
    
    private lazy var collectionView: UICollectionView = { [unowned self] in
    
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsZero
        layout.scrollDirection = .Horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let view = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        view.delegate   = self
        view.dataSource = self
        view.pagingEnabled = true
        view.bounces = false
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.registerClass(BannerViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        return view
        
    }()
    
    
    static private let section  = 3
    static private let middleSection = 1
    static private let fristItemInMiddleSection = 0
    
    public var images = [UIImage]() {
        didSet {
            pageControl.numberOfPages = images.count
            collectionView.reloadData()
            scrollToMiddle()
        }
    }
    
    typealias DoSomething = Void ->Void
    
    private func delay(duration: NSTimeInterval,dosomething: DoSomething) {
        let delta = Int64(Double(NSEC_PER_USEC) * duration)
        dispatch_after( dispatch_time(DISPATCH_TIME_NOW, delta), dispatch_get_main_queue()) { 
            dosomething()
        }
    }
    
    
    @objc private func scrollToMiddle() {
        if images.count > 1 {
            let indexPath = NSIndexPath(forItem:  self.dynamicType.fristItemInMiddleSection, inSection:  self.dynamicType.middleSection)
            
            collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .None, animated: false)
        }
        
    }
    
    override public func willMoveToSuperview(newSuperview: UIView?) {
        do {
            let views = ["collectionView":collectionView]
            addSubview(collectionView)
            // flatMap 将二维数据转为一维数组
            let vhConstraints = [NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|", options: [], metrics: nil, views: views),NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|", options: [], metrics: nil, views: views)].flatMap { (constraints) -> [NSLayoutConstraint] in
                return constraints
            }
            NSLayoutConstraint.activateConstraints(vhConstraints)
        }
        
        do {
            addSubview(pageControl)
            pageControl.rightAnchor.constraintEqualToAnchor(self.rightAnchor, constant: -8).active = true
            pageControl.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor, constant: -8).active = true
        }
        
    }
    
    public override func didMoveToSuperview() {
        
        self .performSelector(#selector(BannerView.scrollToMiddle), withObject: nil, afterDelay: 0.01)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard  let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        layout.itemSize = bounds.size
    }

}

extension BannerView: UICollectionViewDataSource,UICollectionViewDelegate {
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return images.count == 1 ? 1: self.dynamicType.section;
    }
    
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return images.count
    }
    
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.dynamicType.reuseIdentifier, forIndexPath: indexPath) as?  BannerViewCell else {
            return UICollectionViewCell()
        }
        cell.imageView.image = images[indexPath.item]
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        print(indexPath)
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        
        if images.count == 1 {
            return
        }
        
        guard let cell = collectionView.visibleCells().first else {
            return
        }
        
        guard let indexPath =  collectionView.indexPathForCell(cell) else {
            return
        }
        
        
        delay(0.01) { [unowned self] in
            self.pageControl.currentPage = indexPath.item
            let middleIndexPath = NSIndexPath(forItem:  indexPath.item, inSection:  self.dynamicType.middleSection)
            self.collectionView.scrollToItemAtIndexPath(middleIndexPath, atScrollPosition: .None, animated: false)
        }
        
    }
    
    
}
