//
//  ViewController.swift
//  BannerView
//
//  Created by Tanfanfan on 16/6/7.
//  Copyright © 2016年 Tanfanfan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var bannerView: BannerView! {
        
        didSet {
        
            bannerView.images =  (0...3).map { (index) -> UIImage in
                
                return UIImage(named: "image\(index)")!
            }
            
            bannerView.pageControl.currentPageIndicatorTintColor = UIColor.green()
            bannerView.pageControl.pageIndicatorTintColor = UIColor.orange()
            bannerView.deletateCallback = { (bannerView: BannerView, didSelectItem: Int) in
                
                print("bannerView\(didSelectItem)" )
            }
        }
        
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        bannerView.scrollDirection = (bannerView.scrollDirection == .horizontal) ? .vertical : .horizontal
    }


}

