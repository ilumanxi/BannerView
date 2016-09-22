//
//  BannerView.swift
//  BannerView
//
//  Created by Tanfanfan on 16/6/7.
//  Copyright © 2016年 Tanfanfan. All rights reserved.
//

import UIKit

@IBDesignable
public extension UIView { }

public class BannerView: UIView {
    
    public var images: [UIImage]! {
        didSet {
            assert(images.count > 0, "images count cannot be zero")
            pageControl.numberOfPages = images.count
            pageControl.hidesForSinglePage = !carouselForSinglePage
            collectionView.reloadData()
            scrollToMiddle()
        }
    }
    
   typealias DeletateCallback =  (_ bannerView: BannerView, _ didSelectItem: Int) -> Void
    
   var deletateCallback: DeletateCallback?
    
   @IBInspectable  public var  duration: TimeInterval = 2.5 {
        didSet {
            if duration == oldValue  { return }
            removeTimer()
            addTimer()
        }
    }
    
   @IBInspectable public var carouselForSinglePage = false { didSet { collectionView.reloadData() } }
    
   @IBInspectable public var carouselAnimate = true
    
    private var timer: Timer?
    
    @objc fileprivate func addTimer() {
        if case nil = timer  {
            timer = Timer(timeInterval: duration, target: self, selector: #selector(BannerView.carousel), userInfo: nil, repeats: true)
            RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
            timer?.fire()
        }
    }
    
    fileprivate func removeTimer() {
        if case nil = timer  { return }
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func carousel() {
        guard let indexPath = currentVisibleIndexPath() else { return }
        if !carouselAnimate {  removeTimer() }
        let item = indexPath.item + Constant.noncarouselSection
        let middleIndexPath = IndexPath(item:  item, section:indexPath.section)
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
            let item = indexPath.item + Constant.noncarouselSection
            let middleIndexPath = IndexPath(item:  item, section: indexPath.section)
            scrollToItemAtIndexPath(middleIndexPath, animated: true)
        }
        addTimer()
    }
    
   fileprivate class BannerViewCell: UICollectionViewCell {
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
            NSLayoutConstraint.activate([
                NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]|", options: [], metrics: nil, views: views),
                NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageView]|", options: [], metrics: nil, views: views)
                ].flatMap { (constraints) -> [NSLayoutConstraint] in
                    return constraints
            })
        }
    }
    
    fileprivate struct Constant {
        public static let carouselSection          = 3
        public static let noncarouselSection       = 1
        public static let fristItemInMiddleSection = 0
        public static let reuseIdentifier          = String(describing: BannerViewCell.self)
    }
    
    fileprivate  var section: Int {
       return (carouselForSinglePage || images.count > Constant.noncarouselSection) ?
            Constant.carouselSection : Constant.noncarouselSection
    }
    fileprivate  var middleSection: Int {
        return (section == Constant.noncarouselSection) ? Constant.noncarouselSection : (section / 2)
    }
    
    private lazy var collectionView: UICollectionView = { [unowned self] in
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets.zero
        layout.scrollDirection = self.scrollDirection
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.delegate        = self
        view.dataSource      = self
        view.isPagingEnabled = true
        view.bounces         = false
        view.showsVerticalScrollIndicator   = false
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor                = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.register(BannerViewCell.self, forCellWithReuseIdentifier: Constant.reuseIdentifier)
        return view
    }()
    
    private var layout: UICollectionViewFlowLayout { return collectionView.collectionViewLayout as! UICollectionViewFlowLayout }
    
    typealias DoSomething = () -> Void
    
    fileprivate func delay(_ duration: TimeInterval,dosomething: @escaping DoSomething) {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) { 
            dosomething()
        }
    }
    
    fileprivate func scrollToItemAtIndexPath(_ indexPath: IndexPath,animated: Bool){
        func scrollAtIndexPath(_ indexPath: IndexPath) {
            collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition(), animated: animated)
            pageControl.currentPage = indexPath.item
        }
        if indexPath.item >= images.count  {
            let middleIndexPath = IndexPath(item: Constant.fristItemInMiddleSection ,
                                         section: indexPath.section + Constant.noncarouselSection)
            scrollAtIndexPath(middleIndexPath)
            self.perform(#selector(BannerView.scrollToMiddle), with: nil, afterDelay: 0.25)
        }else if indexPath.section >= section {
            let middleIndexPath = IndexPath(item: indexPath.item,
                                         section: middleSection)
            scrollAtIndexPath(middleIndexPath)
        }else {
            scrollAtIndexPath(indexPath)
        }
    }
    
    @objc private func scrollToMiddle() {
        let indexPath = IndexPath(item:  Constant.fristItemInMiddleSection, section:  middleSection)
        scrollToItemAtIndexPath(indexPath, animated: false)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addListening()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addListening()
    }
    
    deinit { removeListening() }
    
    private var observers  = Set<NSObject>()
    
    private var rememberVisibleIndexPath: IndexPath?
    
    private func addListening() {
        observers.insert(NotificationCenter.default.addObserver(forName: NSNotification.Name.UIDeviceOrientationDidChange, object: nil, queue: OperationQueue.main) { [unowned self] (note) in
            self.layout.itemSize = self.bounds.size
            guard let indexPath = self.rememberVisibleIndexPath else { return }
            self.collectionView.reloadData()
            self.scrollToItemAtIndexPath(indexPath, animated: false)
            self.rememberVisibleIndexPath = nil
            self.addTimer()
        } as! NSObject)
        observers.insert(NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillChangeStatusBarFrame, object: nil, queue: OperationQueue.main) { [unowned self] (note) in
                guard let indexPath = self.currentVisibleIndexPath() else { return }
                self.removeTimer()
                self.rememberVisibleIndexPath = indexPath
        } as! NSObject)
    }
    
    private func removeListening() {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }
    
    fileprivate func currentVisibleIndexPath() ->IndexPath? {
        guard let cell = collectionView.visibleCells.first else { return  nil }
        return collectionView.indexPath(for: cell)
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
    
    public override func didMoveToSuperview() { addTimer() }
    public override func willRemoveSubview(_ subview: UIView) { removeTimer() }
    public override func layoutSubviews() {
        super.layoutSubviews()
        layout.itemSize = bounds.size
        collectionView.reloadData()
    }
}

extension BannerView: UICollectionViewDataSource,UICollectionViewDelegate {
    
    public final func numberOfSections(in collectionView: UICollectionView) -> Int { return section }
    
    public final func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return images.count }
    
    public final func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constant.reuseIdentifier,for: indexPath) as?  BannerViewCell else { return UICollectionViewCell() }
        cell.imageView.image = images[indexPath.item]
        return cell
    }
    
    public final func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        do {
            removeTimer()
            addTimer()
        }
        deletateCallback?(self, indexPath.item)
    }
    
    public final func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if section == Constant.noncarouselSection { return }
        delay(0.01) { [unowned self] in
            guard let indexPath =  self.currentVisibleIndexPath() else { return }
            let middleIndexPath = IndexPath(item:indexPath.item, section:  self.middleSection)
            self.scrollToItemAtIndexPath(middleIndexPath, animated: false)
        }
    }
    
    public final func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { removeTimer() }
    
    public final func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        NSObject .cancelPreviousPerformRequests(withTarget: self, selector: #selector(BannerView.addTimer), object: nil)
        self.perform(#selector(BannerView.addTimer), with: nil, afterDelay: 1)
    }
}
