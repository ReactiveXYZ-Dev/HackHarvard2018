/*
 Copyright 2016-present the Material Components for iOS authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit
import MaterialComponents.MaterialPageControl

class ShrineHeaderContentView: UIView, UIScrollViewDelegate {

  var pageControl = MDCPageControl()
  var scrollView = UIScrollView()
  var logoImageView = UIImageView(image: UIImage(named: "vr-glasses"))
  var logoTextImageView = UIImageView(image: UIImage(named: "vr-glasses"))
  fileprivate var pages = NSMutableArray()
  fileprivate var label = UILabel()
  fileprivate var labelDesc = UILabel()
  fileprivate var label2 = UILabel()
  fileprivate var labelDesc2 = UILabel()
  fileprivate var label3 = UILabel()
  fileprivate var labelDesc3 = UILabel()
  fileprivate var cyanBox = UIView()
  fileprivate var cyanBox2 = UIView()
  fileprivate var cyanBox3 = UIView()
  fileprivate var imageView = UIImageView()
  fileprivate var imageView2 = UIImageView()
  fileprivate var imageView3 = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init(coder: NSCoder) {
    super.init(coder: coder)!
  }

  func commonInit() {
    let boundsWidth = bounds.width
    let boundsHeight = bounds.height
    scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    scrollView.delegate = self
    scrollView.isPagingEnabled = true
    scrollView.showsHorizontalScrollIndicator = false
    addSubview(scrollView)
    autoresizingMask = [.flexibleWidth, .flexibleHeight]

    for i in 0...2 {
      let boundsLeft = CGFloat(i) * boundsWidth
      let pageFrame = bounds.offsetBy(dx: boundsLeft, dy: 0)
      let page = UIView(frame:pageFrame)
      page.clipsToBounds = true
      page.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addActions(page: page, index: i)
      pages.add(page)
      scrollView.addSubview(page)
    }

    pageControl.numberOfPages = 3
    pageControl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    let pageControlSize = pageControl.sizeThatFits(bounds.size)
    pageControl.frame = CGRect(x: 0,
                               y: boundsHeight - pageControlSize.height,
                               width: boundsWidth,
                               height: pageControlSize.height)
    pageControl.addTarget(self, action: #selector(didChangePage),
                          for: UIControlEvents.valueChanged)
    addSubview(pageControl)

    addHeaderPages()
    addSubview(logoImageView)
    addSubview(logoTextImageView)
  }
    @objc func presentPortalView() {
        if let controller = UIStoryboard(name: "Portal", bundle: nil).instantiateViewController(withIdentifier: "portalVC") as? PortalViewController {
            if let topVC = UIApplication.getTopMostViewController() {
                topVC.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    @objc func presentGuaGuaLeView() {
        if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "main") as? ViewController {
            if let topVC = UIApplication.getTopMostViewController() {
                controller.mode = "guaguale"
                topVC.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    @objc func presentTimelineView() {
        if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "main") as? ViewController {
            if let topVC = UIApplication.getTopMostViewController() {
                controller.mode = "timeline"
                topVC.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    func addActions(page: UIView, index: Int) {
        switch index {
        case 0:
            let gesture = UITapGestureRecognizer(target: self, action: #selector(self.presentPortalView))
            page.addGestureRecognizer(gesture)
            break
        case 1:
            let gesture = UITapGestureRecognizer(target: self, action: #selector(self.presentGuaGuaLeView))
            page.addGestureRecognizer(gesture)
            break
        case 2:
            let gesture = UITapGestureRecognizer(target: self, action: #selector(self.presentTimelineView))
            page.addGestureRecognizer(gesture)
            break
        default:
            break
        }
    }

  func addHeaderPages() {
    labelDesc2.text = "When Art intersects technology"
    _ = ShrineHeaderPage(page: pages[0] as! UIView,
                         imageView: imageView2,
                         label: label2,
                         labelDesc: labelDesc2,
                         cyanBox: cyanBox2,
                         imageName: "backpack.png",
                         description: "Augmented Reality")
    
    labelDesc.text = "Brilliance? or Destiny?"
    _ = ShrineHeaderPage(page: pages[1] as! UIView,
                         imageView: imageView,
                         label: label,
                         labelDesc: labelDesc,
                         cyanBox: cyanBox,
                         imageName: "jfxmvf/Banksy-Love-is-in-the-Bin.jpg",
                         description: "Love \nIs in the Bin")
    
    labelDesc3.text = "Go beyond NOW. Embrace the Past and the Future"
    _ = ShrineHeaderPage(page: pages[2] as! UIView,
                         imageView: imageView3,
                         label: label3,
                         labelDesc: labelDesc3,
                         cyanBox: cyanBox3,
                         imageName: "fSoyQf/painting-DIFFUSE.png",
                         description: "Glimpse of the Seasons")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    var safeAreaInset: CGFloat = 0
    #if swift(>=3.2)
      if #available(iOS 11.0, *) {
        safeAreaInset = min(self.safeAreaInsets.top, 20)
      }
    #endif
    let boundsWidth = bounds.width
    let boundsHeight = bounds.height
    for i in 0...pages.count - 1 {
      let boundsLeft = CGFloat(i) * boundsWidth
      let pageFrame = bounds.offsetBy(dx: boundsLeft, dy: 0)
      let page = pages[i] as! UIView
      page.frame = pageFrame
    }
    let pageControlSize = pageControl.sizeThatFits(bounds.size)
    pageControl.frame = CGRect(x: 0, y: boundsHeight - pageControlSize.height, width: boundsWidth,
      height: pageControlSize.height)
    let scrollWidth: CGFloat = boundsWidth * CGFloat(pages.count)
    scrollView.frame = CGRect(x: 0, y: 0, width: boundsWidth, height: boundsHeight)
    scrollView.contentSize = CGSize(width: scrollWidth, height: boundsHeight)

    let scrollViewOffsetX = CGFloat(pageControl.currentPage) * boundsWidth
    scrollView.setContentOffset(CGPoint(x: scrollViewOffsetX, y: 0), animated: false)
    logoImageView.frame = CGRect(x: 0, y: 0, width: 60, height: 40)
    logoImageView.center = CGPoint(x: (frame.size.width) / 2, y: 44 + safeAreaInset)
    logoImageView.contentMode = .scaleAspectFit
    logoTextImageView.frame = CGRect(x: 0, y: 0, width: 100, height: 70)
    logoTextImageView.center = CGPoint(x: (frame.size.width) / 2, y: 44 + safeAreaInset)
    logoTextImageView.contentMode = .scaleAspectFit

    let labelWidth = CGFloat(250)
    let labelWidthFrame = CGRect(x: frame.size.width - labelWidth,
      y: 90, width: labelWidth, height: label.frame.size.height)

    let labelDescWidth = CGFloat(200)
    let labelDescWidthFrame = CGRect(x: frame.size.width - labelDescWidth - 10,
      y: 190, width: labelDescWidth, height: 40)

    label.frame = labelWidthFrame
    labelDesc.frame = labelDescWidthFrame
    label2.frame = labelWidthFrame
    labelDesc2.frame = labelDescWidthFrame
    label3.frame = labelWidthFrame
    labelDesc3.frame = labelDescWidthFrame

    let cyanBoxFrame = CGRect(x: frame.size.width - 210, y: 180, width: 100, height: 8)
    cyanBox.frame = cyanBoxFrame
    cyanBox2.frame = cyanBoxFrame
    cyanBox3.frame = cyanBoxFrame

    imageView.frame = CGRect(x: -180, y: 120, width: 420, height: frame.size.height)
    imageView2.frame = CGRect(x: -220, y: 110, width: 420, height: frame.size.height)
    imageView3.frame = CGRect(x: -180, y: 40, width: 420, height: frame.size.height)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    pageControl.scrollViewDidScroll(scrollView)
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    pageControl.scrollViewDidEndDecelerating(scrollView)
  }

  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    pageControl.scrollViewDidEndScrollingAnimation(scrollView)
  }

    @objc func didChangePage(_ sender: MDCPageControl) {
    var offset = scrollView.contentOffset
    offset.x = CGFloat(sender.currentPage) * scrollView.bounds.size.width
    scrollView.setContentOffset(offset, animated: true)
  }

}
