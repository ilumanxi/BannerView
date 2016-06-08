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
            
            var images = [UIImage]()
            
            for index in 0...3 {
                
                images.append(UIImage(named: "image\(index)")!)
            }
            
            bannerView.images = images
            
            bannerView.pageControl.currentPageIndicatorTintColor = UIColor.purpleColor()
            bannerView.pageControl.pageIndicatorTintColor = UIColor.blueColor()
            bannerView.deletateCallback = { (bannerView: BannerView, didSelectItem: Int) in
                
                print(didSelectItem)
            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

   
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        
        if bannerView.scrollDirection == .Horizontal {
            bannerView.scrollDirection = .Vertical
        }else {
            bannerView.scrollDirection = .Horizontal
        }
        
        
    }


}

