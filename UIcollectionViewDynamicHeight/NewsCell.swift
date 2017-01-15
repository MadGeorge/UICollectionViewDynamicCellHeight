import UIKit

class NewsCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageViewAligned!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var csImageWidth: NSLayoutConstraint!
    
    func setup(news: News) {
        imageView.backgroundColor = UIColor.clearColor()
        imageView.setImageWith(news.imageURL, placeholderColor: UIColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1))
        titleLabel.text = news.title
        detailsLabel.text = news.details
        dateLabel.text = news.dateFormatted
    }
    
    static func calculateHeightFor(titleText: String, detailsText: String, width: CGFloat) -> CGFloat {
        let horisontalOffsets: CGFloat = 16 + 115 + 8 + 18 // space to image + image width + space to image + space to container
        let labelsBlockWidth = width - horisontalOffsets
        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.numberOfLines = 4
        titleLabel.preferredMaxLayoutWidth = labelsBlockWidth
        titleLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightSemibold)
        
        let detailsLabel = UILabel()
        detailsLabel.text = detailsText
        detailsLabel.numberOfLines = 0
        detailsLabel.preferredMaxLayoutWidth = labelsBlockWidth
        detailsLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightRegular)
        
        let titleHeight = titleLabel.intrinsicContentSize().height
        let detailsHeight = detailsLabel.intrinsicContentSize().height
        
        let verticalOffsets: CGFloat = 16 + (6 + 11 + 4) + 8 + 16 // top + Date label with spaces + interlabels offset + bottom space
        
        let height = max(80, titleHeight + detailsHeight + verticalOffsets) // Minimum cell height will be 80
        
        return height
    }
}

/// Support and helpers

extension News {
    var dateFormatted: String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd MMMM YYYY HH:mm"
        return formatter.stringFromDate(date)
    }
}

extension NSFileManager {
    class var cachesUrl: NSURL {
        get {
            return NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!)
        }
    }
    
    class func fileUrlInsideCacheDir(fileName: String) -> NSURL {
        return cachesUrl.URLByAppendingPathComponent(fileName)
    }
}

extension UIImageView {
    func setImageWith(urlPath: String, placeholderColor: UIColor? = nil) {
        image = nil
        
        let currentColor = backgroundColor // remember to restore
        if let backColor = placeholderColor {
            backgroundColor = backColor
        }
        
        func fillOutImage(img: UIImage) {
            image = img
            backgroundColor = currentColor
        }
        
        if let url = NSURL(string: urlPath) {
            if let imageData = ImagesCacher.restore(withURL: url) {
                fillOutImage(imageData)
                return
            }
            
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            config.URLCache = NSURLCache.sharedURLCache()
            let session = NSURLSession(configuration: config)
            let task = session.dataTaskWithURL(url){ data, response, error in
                if let data = data, let img = UIImage(data: data) {
                    dispatch_async(dispatch_get_main_queue(), {
                        ImagesCacher.storeImage(data, forURL: url)
                        fillOutImage(img)
                    })
                }
            }
            task.resume()
        }
    }
}

class ImagesCacher {
    private static var isInitialised = false
    private static let cacheDirName = "imagesCache"
    private static let cacheDirURL = NSFileManager.fileUrlInsideCacheDir(cacheDirName)
    
    private static var inMemoryCache = [Int: UIImage]()
    
    static func checkCacheDir() {
        var isDir = ObjCBool(false)
        let exist = NSFileManager.defaultManager().fileExistsAtPath(cacheDirURL.path!, isDirectory: &isDir)
        if !(exist && Bool(isDir)) {
            _ = try? NSFileManager.defaultManager().createDirectoryAtURL(cacheDirURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    static func storeImage(imageData: NSData, forURL url: NSURL) {
        if !isInitialised { checkCacheDir() }
        _ = try? imageData.writeToURL(NSFileManager.fileUrlInsideCacheDir("\(cacheDirName)/com.cache.img\(url.hashValue)"), options: [.DataWritingAtomic])
        inMemoryCache[url.hashValue] = UIImage(data: imageData)
    }
    
    static func restore(withURL url: NSURL) -> UIImage? {
        if !isInitialised { checkCacheDir() }
        
        if let img = inMemoryCache[url.hashValue] {
            return img
        }
        
        if let data = NSData(contentsOfURL: NSFileManager.fileUrlInsideCacheDir("\(cacheDirName)/com.cache.img\(url.hashValue)")) {
            inMemoryCache[url.hashValue] = UIImage(data: data)
            return inMemoryCache[url.hashValue]
        }
        return nil
    }
    
    static func clearAllCache() {
        inMemoryCache = [:]
        _ = try? NSFileManager.defaultManager().removeItemAtURL(cacheDirURL)
    }
}