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
    
   @IBInspectable  public var  duration: TimeInterval = 2.5 {
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
    
    private var timer: Timer?
    
    @objc private func addTimer() {
        if let _ = timer {
            return
        }
        timer = Timer(timeInterval: duration, target: self, selector: #selector(BannerView.carousel), userInfo: nil, repeats: true)
        RunLoop.current().add(timer!, forMode: RunLoopMode.commonModes)
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
        
        let item  = (indexPath as NSIndexPath).item + Section.noncarouselSection
        let middleIndexPath = IndexPath(item:  item, section:  (indexPath as NSIndexPath).section)
        scrollToItemAtIndexPath(middleIndexPath, animated: true)
    }
    
    public var scrollDirection: UICollectionViewScrollDirection = .horizontal {
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
        pageControl.addTarget(self, action: #selector(BannerView.valueChange(_:)), for: .valueChanged)
        return pageControl
    }()
    
    @objc private func valueChange(_ pageControl: UIPageControl) {
        
        removeTimer()
        do {
            let indexPath = currentVisibleIndexPath()!
            let item  = (indexPath as NSIndexPath).item + Section.noncarouselSection
            let middleIndexPath = IndexPath(item:  item, section:  (indexPath as NSIndexPath).section)
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
                NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]|", options: [], metrics: nil, views: views),
                NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageView]|", options: [], metrics: nil, views: views)
            ].flatMap { (constraints) -> [NSLayoutConstraint] in
                return constraints
            }
            NSLayoutConstraint.activate(vhConstraints)
            
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
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.delegate      = self
        view.dataSource    = self
        view.isPagingEnabled = true
        view.bounces       = false
        view.showsVerticalScrollIndicator   = false
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor                = UIColor.clear()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.register(BannerViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        return view
    }()
    
    private var layout: UICollectionViewFlowLayout {
        
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    typealias DoSomething = (Void) ->Void
    
    private func delay(_ duration: TimeInterval,dosomething: DoSomething) {
        let delta = Int64(Double(NSEC_PER_USEC) * duration)
        DispatchQueue.main.after( when: DispatchTime.now() + Double(delta) / Double(NSEC_PER_SEC)) { 
            dosomething()
        }
    }
    
    private func scrollToItemAtIndexPath(_ indexPath: IndexPath,animated: Bool){
        func scrollAtIndexPath(_ indexPath: IndexPath) {
            collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition(), animated: animated)
            pageControl.currentPage = (indexPath as NSIndexPath).item
        }
        if (indexPath as NSIndexPath).item >= images.count  {
            let middleIndexPath = IndexPath(item:  Section.fristItemInMiddleSection ,
                                            section:  (indexPath as NSIndexPath).section + Section.noncarouselSection)
            scrollAtIndexPath(middleIndexPath)
            self.perform(#selector(BannerView.scrollToMiddle), with: nil, afterDelay: 0.25)
        }else if (indexPath as NSIndexPath).section >= section {
            let middleIndexPath = IndexPath(item: (indexPath as NSIndexPath).item ,
                                            section: middleSection)
            scrollAtIndexPath(middleIndexPath)
        }else {
            scrollAtIndexPath(indexPath)
        }
    }
    
    @objc private func scrollToMiddle() {
        let indexPath = IndexPath(item:  Section.fristItemInMiddleSection, section:  middleSection)
        scrollToItemAtIndexPath(indexPath, animated: false)
    }
    
    override public func willMove(toSuperview newSuperview: UIView?) {
        do {
            let views = ["collectionView":collectionView]
            addSubview(collectionView)
            let vhConstraints = [
                NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView]|", options: [], metrics: nil, views: views),
                NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectionView]|", options: [], metrics: nil, views: views)
                ].flatMap { (constraints) -> [NSLayoutConstraint] in
                return constraints
            }
            NSLayoutConstraint.activate(vhConstraints)
        }
        
        do {
            addSubview(pageControl)
            pageControl.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            pageControl.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8).isActive = true
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
        NotificationCenter.default().addObserver(self, selector: #selector(BannerView.deviceOrientationDidChangeNotification(_:)),
                                                         name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(BannerView.applicationWillChangeStatusBarFrameNotification(_:)), name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame, object: nil)
    }
    
    private func removeListening() {
        NotificationCenter.default().removeObserver(self)
    }
    
    private var rememberVisibleIndexPath: IndexPath?
    
    @objc private func applicationWillChangeStatusBarFrameNotification(_ notification: Notification) {
        
        guard let indexPath = currentVisibleIndexPath() else {
            return
        }
        removeTimer()
        rememberVisibleIndexPath = indexPath
    }
    
    @objc private func deviceOrientationDidChangeNotification(_ notification: Notification) {
        layout.itemSize = bounds.size
        guard let indexPath = rememberVisibleIndexPath else {
            return
        }
        collectionView.reloadData()
        scrollToItemAtIndexPath(indexPath, animated: false)
        rememberVisibleIndexPath = nil
        addTimer()
    }
    
    private func currentVisibleIndexPath() ->IndexPath? {
        guard let cell = collectionView.visibleCells().first else {
            return  nil
        }
        return collectionView.indexPath(for: cell)
    }
    
    public override func didMoveToSuperview() {
        self .perform(#selector(BannerView.scrollToMiddle), with: nil, afterDelay: 0.01)
        addTimer()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layout.itemSize = bounds.size
        collectionView.reloadData()
    }

}

extension BannerView: UICollectionViewDataSource,UICollectionViewDelegate {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return section;
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return images.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.dynamicType.reuseIdentifier,
                                                                               for: indexPath) as?  BannerViewCell else {
            return UICollectionViewCell()
        }
        cell.imageView.image = images[(indexPath as NSIndexPath).item]
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        do {
            removeTimer()
            addTimer()
        }
        
        deletateCallback?(bannerView: self, didSelectItem: (indexPath as NSIndexPath).item)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if section == Section.noncarouselSection {
            return
        }
        delay(0.01) { [unowned self] in
            guard let indexPath =  self.currentVisibleIndexPath() else {
                return
            }
            let middleIndexPath = IndexPath(item:  (indexPath as NSIndexPath).item, section:  self.middleSection)
            self.scrollToItemAtIndexPath(middleIndexPath, animated: false)
        }
        
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        removeTimer()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        NSObject .cancelPreviousPerformRequests(withTarget: self, selector: #selector(BannerView.addTimer), object: nil)
        self.perform(#selector(BannerView.addTimer), with: nil, afterDelay: 1)
    }
}
