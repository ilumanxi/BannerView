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
    
    public var images = [UIImage]() {
        didSet {
            pageControl.numberOfPages = images.count
            pageControl.hidesForSinglePage = !carouselForSinglePage
            collectionView.reloadData()
            scrollToMiddle()
        }
    }
    
   typealias DeletateCallback = (bannerView: BannerView, didSelectItem: Int) ->Void
    
   var deletateCallback: DeletateCallback?
    
   @IBInspectable  public var  duration: NSTimeInterval = 2.5 {
        didSet {
            if duration == oldValue  {
                return
            }
            removeTimer()
            addTimer()
        }
    }
    
    @IBInspectable public var carouselForSinglePage = false {
        didSet {
            collectionView.reloadData()
        }
    }
    
   @IBInspectable public var carouselAnimate = true
    
    private var timer: NSTimer?
    
    @objc private func addTimer() {
        if let _ = timer {
            return
        }
        timer = NSTimer(timeInterval: duration, target: self, selector: #selector(BannerView.carousel), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
        timer?.fire()
    }
    
    private func removeTimer() {
        guard let _ = timer else {
            return
        }
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func carousel() {
        guard let indexPath = currentVisibleIndexPath() else {
            return
        }
        
        if !carouselAnimate {
            
            removeTimer()
        }
        
        let item  = indexPath.item + Section.noncarouselSection
        let middleIndexPath = NSIndexPath(forItem:  item, inSection:  indexPath.section)
        scrollToItemAtIndexPath(middleIndexPath, animated: true)
    }
    
    public var scrollDirection: UICollectionViewScrollDirection = .Horizontal {
        didSet {
            func layoutDirection() {
                layout.scrollDirection = scrollDirection
                collectionView.reloadData()
            }
            guard let indexPath = currentVisibleIndexPath() else {
                layoutDirection()
                return
            }
            layoutDirection()
            scrollToItemAtIndexPath(indexPath, animated: false)
        }
    }
    
    private(set) lazy var pageControl: UIPageControl = { [unowned self] in
       let pageControl =  UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.addTarget(self, action: #selector(BannerView.valueChange(_:)), forControlEvents: .ValueChanged)
        return pageControl
    }()
    
    @objc private func valueChange(pageControl: UIPageControl) {
        
        removeTimer()
        do {
            let indexPath = currentVisibleIndexPath()!
            let item  = indexPath.item + Section.noncarouselSection
            let middleIndexPath = NSIndexPath(forItem:  item, inSection:  indexPath.section)
            scrollToItemAtIndexPath(middleIndexPath, animated: true)
        }
        addTimer()
    }
    
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
            let vhConstraints = [
                NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: [], metrics: nil, views: views),
                NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|", options: [], metrics: nil, views: views)
            ].flatMap { (constraints) -> [NSLayoutConstraint] in
                return constraints
            }
            NSLayoutConstraint.activateConstraints(vhConstraints)
            
        }
    }
    
    private struct Section {
         static let carouselSection = 3
         static let noncarouselSection = 1
         static let fristItemInMiddleSection = 0
    }
    
    private static let reuseIdentifier = String(BannerViewCell)
    private  var section: Int {
       return (carouselForSinglePage || images.count > Section.noncarouselSection) ?
            Section.carouselSection : Section.noncarouselSection
    }
    private  var middleSection: Int {
        
        return (section == Section.noncarouselSection) ? Section.noncarouselSection : (section / 2)
    }
    
    private lazy var collectionView: UICollectionView = { [unowned self] in
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsZero
        layout.scrollDirection = self.scrollDirection
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let view = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        view.delegate      = self
        view.dataSource    = self
        view.pagingEnabled = true
        view.bounces       = false
        view.showsVerticalScrollIndicator   = false
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor                = UIColor.clearColor()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.registerClass(BannerViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        return view
    }()
    
    private var layout: UICollectionViewFlowLayout {
        
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    typealias DoSomething = Void ->Void
    
    private func delay(duration: NSTimeInterval,dosomething: DoSomething) {
        let delta = Int64(Double(NSEC_PER_USEC) * duration)
        dispatch_after( dispatch_time(DISPATCH_TIME_NOW, delta), dispatch_get_main_queue()) { 
            dosomething()
        }
    }
    
    private func scrollToItemAtIndexPath(indexPath: NSIndexPath,animated: Bool){
        func scrollAtIndexPath(indexPath: NSIndexPath) {
            collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .None, animated: animated)
            pageControl.currentPage = indexPath.item
        }
        if indexPath.item >= images.count  {
            let middleIndexPath = NSIndexPath(forItem:  Section.fristItemInMiddleSection ,
                                            inSection:  indexPath.section + Section.noncarouselSection)
            scrollAtIndexPath(middleIndexPath)
            self.performSelector(#selector(BannerView.scrollToMiddle), withObject: nil, afterDelay: 0.25)
        }else if indexPath.section >= section {
            let middleIndexPath = NSIndexPath(forItem: indexPath.item ,
                                            inSection: middleSection)
            scrollAtIndexPath(middleIndexPath)
        }else {
            scrollAtIndexPath(indexPath)
        }
    }
    
    @objc private func scrollToMiddle() {
        let indexPath = NSIndexPath(forItem:  Section.fristItemInMiddleSection, inSection:  middleSection)
        scrollToItemAtIndexPath(indexPath, animated: false)
    }
    
    override public func willMoveToSuperview(newSuperview: UIView?) {
        do {
            let views = ["collectionView":collectionView]
            addSubview(collectionView)
            let vhConstraints = [
                NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|", options: [], metrics: nil, views: views),
                NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|", options: [], metrics: nil, views: views)
                ].flatMap { (constraints) -> [NSLayoutConstraint] in
                return constraints
            }
            NSLayoutConstraint.activateConstraints(vhConstraints)
        }
        
        do {
            addSubview(pageControl)
            pageControl.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
            pageControl.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor, constant: -8).active = true
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addListening()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addListening()
    }
    
    deinit {
        removeListening()
    }
    
    private func addListening() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BannerView.deviceOrientationDidChangeNotification(_:)),
                                                         name: UIDeviceOrientationDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BannerView.applicationWillChangeStatusBarFrameNotification(_:)), name: UIApplicationWillChangeStatusBarFrameNotification, object: nil)
    }
    
    private func removeListening() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private var rememberVisibleIndexPath: NSIndexPath?
    
    @objc private func applicationWillChangeStatusBarFrameNotification(notification: NSNotification) {
        
        guard let indexPath = currentVisibleIndexPath() else {
            return
        }
        removeTimer()
        rememberVisibleIndexPath = indexPath
    }
    
    @objc private func deviceOrientationDidChangeNotification(notification: NSNotification) {
        layout.itemSize = bounds.size
        guard let indexPath = rememberVisibleIndexPath else {
            return
        }
        collectionView.reloadData()
        scrollToItemAtIndexPath(indexPath, animated: false)
        rememberVisibleIndexPath = nil
        addTimer()
    }
    
    private func currentVisibleIndexPath() ->NSIndexPath? {
        guard let cell = collectionView.visibleCells().first else {
            return  nil
        }
        return collectionView.indexPathForCell(cell)
    }
    
    public override func didMoveToSuperview() {
        self .performSelector(#selector(BannerView.scrollToMiddle), withObject: nil, afterDelay: 0.01)
        addTimer()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layout.itemSize = bounds.size
        collectionView.reloadData()
    }

}

extension BannerView: UICollectionViewDataSource,UICollectionViewDelegate {
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return section;
    }
    
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return images.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.dynamicType.reuseIdentifier,
                                                                               forIndexPath: indexPath) as?  BannerViewCell else {
            return UICollectionViewCell()
        }
        cell.imageView.image = images[indexPath.item]
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        deletateCallback?(bannerView: self, didSelectItem: indexPath.item)
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if section == Section.noncarouselSection {
            return
        }
        delay(0.01) { [unowned self] in
            guard let indexPath =  self.currentVisibleIndexPath() else {
                return
            }
            let middleIndexPath = NSIndexPath(forItem:  indexPath.item, inSection:  self.middleSection)
            self.scrollToItemAtIndexPath(middleIndexPath, animated: false)
        }
        
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        removeTimer()
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        NSObject .cancelPreviousPerformRequestsWithTarget(self, selector: #selector(BannerView.addTimer), object: nil)
        self.performSelector(#selector(BannerView.addTimer), withObject: nil, afterDelay: 1)
    }
}
