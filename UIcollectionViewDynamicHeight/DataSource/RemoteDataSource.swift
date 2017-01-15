import Foundation

protocol RemoteDataSourceObserver {
    func changed(dataSource: RemoteDataSource)
}

class RemoteDataSource {
    
    struct Cache {
        let data: [News]
        let expiredAt: NSDate
        
        var isExpired: Bool {
            return NSDate().compare(expiredAt) != .OrderedAscending
        }
    }
    
    /**
     Describe state of the source
     
     - **Initialised:** Just created
     - **Done:** Data loading complete
     - **Loading:** Loading in progress
     */
    enum State {
        case Initialised, Done, Loading
    }
    
    private var lastLoadingTask: NSURLSessionTask?
    private let url = NSURL(string: "https://newsapi.org/v1/articles?source=google-news&apiKey=949ea3c933384a4c9c865b4fa3b6a620")!
    private var observers = [RemoteDataSourceObserver]()
    private var finishUpdateCallback: ((news: [News]) -> Void)?
    
    var lastValidData = Cache(data: [], expiredAt: NSDate())
    var state = State.Initialised
    
    func add(observer obj: Any, with handler: (dataSource: RemoteDataSource) -> Void) {
        observers.append(ClosureObserver(closure: handler))
    }
    
    func loadIfNeeded() {
        if !lastValidData.isExpired {
            notifyObservers()
            return
        }
        
        lastLoadingTask?.cancel()
        
        state = .Loading
        notifyObservers()
        
        let sesion = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        lastLoadingTask = sesion.dataTaskWithURL(url) {[weak self] data, response, error in
            var news = [News]()
            
            if let data = data {
                do {
                    if let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject] {
                        if let articlesJson = json["articles"] as? [[String: AnyObject]] {
                            for art in articlesJson {
                                if let article = News(json: art) {
                                    news.append(article)
                                }
                            }
                        }
                    }
                } catch let e {
                    print("RemoteDataSource: parse json error", e)
                }
            }
            
            news.sortInPlace{ $0.0.date.compare($0.1.date) == .OrderedAscending }
            
            self?.state = .Done
            self?.lastValidData = Cache(data: news, expiredAt: NSDate().dateByAddingTimeInterval(30000))
            self?.notifyObservers()
        }
        
        lastLoadingTask?.resume()
    }
    
    private func notifyObservers() {
        for obsrv in observers {
            dispatch_async(dispatch_get_main_queue(), {
                obsrv.changed(self)
            })
        }
    }
    
    func invalidateCache() {
        lastValidData = Cache(data: [], expiredAt: NSDate())
    }
    
}

extension News {
    init?(json: [String: AnyObject]) {
        guard
        let title = json["title"] as? String,
        let details = json["description"] as? String,
        let publishedAt = json["publishedAt"] as? String
        else { return nil }
        
        self.title = title
        self.details = details
        self.imageURL = (json["urlToImage"] as? String) ?? ""
        
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "YYYY-MM-dd'T'HH:MM:ss'Z'"
        
        self.date = dateFormat.dateFromString(publishedAt) ?? NSDate()
    }
}

private struct ClosureObserver: RemoteDataSourceObserver {
    let closure: (dataSource: RemoteDataSource) -> Void
    
    func changed(dataSource: RemoteDataSource) {
        closure(dataSource: dataSource)
    }
}