import UIKit

class ViewController: UIViewController,UiScrollViewDelegate,TAPageControlDelegate {
    var index = 0
    var timer = Timer()

    var customPageControl2 = TAPageControl()

    @IBQutlet weak var scrollView: UIScrollView!

    var imageData = NSArray()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageData = [ "image1.png" , "image2.png" , "image3.png" ]
       settingScrollView()

    }

    func settingScrollView(){
        //스크롤뷰에 이미지를 셋팅
         for i in 0..<self.imageData.count {
            print(i)
            let xPos = self.view.frame.size.width * CGFloat(i)
            let imageView = UIImageView(frame: CGRect(x:xPos, y: 0, width: self.view.frame.width, height:
                self.scrollView.frame.size.height))
            imageView.contentMode = .scaleAspectFill
            imageView.image = UIImage(named: self.imageData[i] as! String )
            self.scrollView.addSubview(imageView)
        }
         self.scrollView.delegate = self
         index=0

         self.customPageControl2 = TAPageControl(frame: CGRect(x: 20, y:
         self.scrollView.frame.origin.y+self.scrollView.frame.size.height, width: self.scrollView.frame.size.width,
         height: 40 ))
         self.customPageControl2.delegate = self
         self.customPageControl2.numberOfPages = self.imageData.count
         //스크롤뷰 하단의 점표시하는코드
         self.customPageControl2.dotSize = CGSize(width: 20, height: 20)
         self.scrollView.contentSize = CGSize(width: self.view.frame.size.width * CGFloat(self.imageData.count), height:
            self.scrollView.frame.size.height)
         self.view.addSubview(slef.customPageControl2)
    }

    override func viewDidAppear( animated: Bool ) {
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(runImages), userInfo:nil,
            repeats: true )
    }

    override func viewDidDisappear( animated: Bool ){
        timer.invalidate()
    }

    @objc func runImages(){
        self.customPageControl2.currentpage = indexif index == self.imageData.count - 1 {
            index=0
        }else{
            index = index + 1
        }
        self.taPageControl(self.custompageControl2, didSelectpageAt: index)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = scrollView.contentOffset.x / scrollView.frame.size.width
        self.customPageControl2.currentpage = Int(pageIndex)
        index = Int(pageIndex)
    }

    func  taPageControl(_ pageControl: TAPageControl!, didSelectpageAt currentIndex: Int) {
        index = currentIndex
        self.scrollView.serollRectToVisible(CGRect(x: self.view.frame.size.width * CGFloat(currentindex), y: 0, width:
            self.view.frame.width, height: self.scrollView.frame.size.height), animated: true)
    }

}