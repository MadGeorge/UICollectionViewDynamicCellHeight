import UIKit

class NewsCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageViewAligned!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var csImageWidth: NSLayoutConstraint!
    
    func setup(_ news: News) {
        imageView.backgroundColor = UIColor.clear
        imageView.setImageWith(news.imageURL, placeholderColor: UIColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1))
        titleLabel.text = news.title
        detailsLabel.text = news.details
        dateLabel.text = news.dateFormatted
    }
    
    static func calculateHeightFor(_ titleText: String, detailsText: String, width: CGFloat) -> CGFloat {
        let horisontalOffsets: CGFloat = 16 + 115 + 8 + 18 // space to image + image width + space to image + space to container
        let labelsBlockWidth = width - horisontalOffsets
        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.numberOfLines = 4
        titleLabel.preferredMaxLayoutWidth = labelsBlockWidth
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightSemibold)
        
        let detailsLabel = UILabel()
        detailsLabel.text = detailsText
        detailsLabel.numberOfLines = 0
        detailsLabel.preferredMaxLayoutWidth = labelsBlockWidth
        detailsLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
        
        let titleHeight = titleLabel.intrinsicContentSize.height
        let detailsHeight = detailsLabel.intrinsicContentSize.height
        
        let verticalOffsets: CGFloat = 16 + (6 + 11 + 4) + 8 + 16 // top + Date label with spaces + interlabels offset + bottom space
        
        let height = max(80, titleHeight + detailsHeight + verticalOffsets) // Minimum cell height will be 80
        
        return height
    }
}

/// Support and helpers

extension News {
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM YYYY HH:mm"
        return formatter.string(from: date as Date)
    }
}

extension FileManager {
    class var cachesUrl: URL {
        get {
            return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
        }
    }
    
    class func fileUrlInsideCacheDir(_ fileName: String) -> URL {
        return cachesUrl.appendingPathComponent(fileName)
    }
}

extension UIImageView {
    func setImageWith(_ urlPath: String, placeholderColor: UIColor? = nil) {
        image = nil
        
        let currentColor = backgroundColor // remember to restore
        if let backColor = placeholderColor {
            backgroundColor = backColor
        }
        
        func fillOutImage(_ img: UIImage) {
            image = img
            backgroundColor = currentColor
        }
        
        if let url = URL(string: urlPath) {
            if let imageData = ImagesCacher.restore(withURL: url) {
                fillOutImage(imageData)
                return
            }
            
            let config = URLSessionConfiguration.default
            config.urlCache = URLCache.shared
            let session = URLSession(configuration: config)
            let task = session.dataTask(with: url, completionHandler: { data, response, error in
                if let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async(execute: {
                        ImagesCacher.storeImage(data, forURL: url)
                        fillOutImage(img)
                    })
                }
            })
            task.resume()
        }
    }
}

class ImagesCacher {
    fileprivate static var isInitialised = false
    fileprivate static let cacheDirName = "imagesCache"
    fileprivate static let cacheDirURL = FileManager.fileUrlInsideCacheDir(cacheDirName)
    
    fileprivate static var inMemoryCache = [Int: UIImage]()
    
    static func checkCacheDir() {
        var isDir = ObjCBool(false)
        let exist = FileManager.default.fileExists(atPath: cacheDirURL.path, isDirectory: &isDir)
        if !(exist && isDir.boolValue) {
            _ = try? FileManager.default.createDirectory(at: cacheDirURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    static func storeImage(_ imageData: Data, forURL url: URL) {
        if !isInitialised { checkCacheDir() }
        _ = try? imageData.write(to: FileManager.fileUrlInsideCacheDir("\(cacheDirName)/com.cache.img\(url.hashValue)"), options: [.atomic])
        inMemoryCache[url.hashValue] = UIImage(data: imageData)
    }
    
    static func restore(withURL url: URL) -> UIImage? {
        if !isInitialised { checkCacheDir() }
        
        if let img = inMemoryCache[url.hashValue] {
            return img
        }
        
        if let data = try? Data(contentsOf: FileManager.fileUrlInsideCacheDir("\(cacheDirName)/com.cache.img\(url.hashValue)")) {
            inMemoryCache[url.hashValue] = UIImage(data: data)
            return inMemoryCache[url.hashValue]
        }
        return nil
    }
    
    static func clearAllCache() {
        inMemoryCache = [:]
        _ = try? FileManager.default.removeItem(at: cacheDirURL)
    }
}
