import Foundation

protocol RemoteDataSourceObserver {
    func changed(_ dataSource: RemoteDataSource)
}

class RemoteDataSource {
    
    struct Cache {
        let data: [News]
        let expiredAt: Date
        
        var isExpired: Bool {
            return Date().compare(expiredAt) != .orderedAscending
        }
    }
    
    /**
     Describe state of the source
     
     - **Initialised:** Just created
     - **Done:** Data loading complete
     - **Loading:** Loading in progress
     */
    enum State {
        case initialised, done, loading
    }
    
    fileprivate var lastLoadingTask: URLSessionTask?
    fileprivate let url = URL(string: "https://newsapi.org/v1/articles?source=google-news&apiKey=949ea3c933384a4c9c865b4fa3b6a620")!
    fileprivate var observers = [RemoteDataSourceObserver]()
    fileprivate var finishUpdateCallback: ((_ news: [News]) -> Void)?
    
    var lastValidData = Cache(data: [], expiredAt: Date())
    var state = State.initialised
    
    func add(observer obj: Any, with handler: @escaping (_ dataSource: RemoteDataSource) -> Void) {
        observers.append(ClosureObserver(closure: handler))
    }
    
    func loadIfNeeded() {
        if !lastValidData.isExpired {
            notifyObservers()
            return
        }
        
        lastLoadingTask?.cancel()
        
        state = .loading
        notifyObservers()
        
        let sesion = URLSession(configuration: URLSessionConfiguration.default)
        lastLoadingTask = sesion.dataTask(with: url, completionHandler: {[weak self] data, response, error in
            var news = [News]()
            
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
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
            
            news.sort{ $0.0.date.compare($0.1.date as Date) == .orderedAscending }
            
            self?.state = .done
            self?.lastValidData = Cache(data: news, expiredAt: Date().addingTimeInterval(30000))
            self?.notifyObservers()
        }) 
        
        lastLoadingTask?.resume()
    }
    
    fileprivate func notifyObservers() {
        for obsrv in observers {
            DispatchQueue.main.async(execute: {
                obsrv.changed(self)
            })
        }
    }
    
    func invalidateCache() {
        lastValidData = Cache(data: [], expiredAt: Date())
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
        
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "YYYY-MM-dd'T'HH:MM:ss'Z'"
        
        self.date = dateFormat.date(from: publishedAt) ?? Date()
    }
}

private struct ClosureObserver: RemoteDataSourceObserver {
    let closure: (_ dataSource: RemoteDataSource) -> Void
    
    func changed(_ dataSource: RemoteDataSource) {
        closure(dataSource)
    }
}
