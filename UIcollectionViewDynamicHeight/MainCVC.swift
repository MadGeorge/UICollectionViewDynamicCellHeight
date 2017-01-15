import UIKit

class MainCVC: UICollectionViewController {

    let dataSource = RemoteDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup required delegate for custom layout
        let layout = collectionViewLayout as! DynamicHeightLayout
        layout.delegate = self
        
        updateColumnsNumberForOrientation(isPortrait(UIApplication.shared.statusBarOrientation))
        
        setupPullToRefreshControl()
        
        handleDataSourceUpdates()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if dataSource.state == .initialised {
            collectionView?.setContentOffset(CGPoint(x: 0, y:  collectionView!.contentOffset.y - refresh.frame.size.height), animated: true)
            refresh.beginRefreshing()
            pullToRefreshAction()
        }
    }
    
    // We want to display different number of columns for big and small screens and different orientations
    func updateColumnsNumberForOrientation(_ isPortrait: Bool) {
        let layout = collectionViewLayout as! DynamicHeightLayout
        print(traitCollection.verticalSizeClass.rawValue, traitCollection.horizontalSizeClass.rawValue)
        let isBig = traitCollection.verticalSizeClass == .regular && traitCollection.horizontalSizeClass == .regular
        let columnsCountNarrow = isBig ? 2 : 1
        let columnsCountWidth = isBig ? 3 : 2
        layout.numberOfColumns = isPortrait ? columnsCountNarrow : columnsCountWidth
    }
    
    fileprivate var refresh = UIRefreshControl()
    func setupPullToRefreshControl() {
        refresh.addTarget(self, action: #selector(pullToRefreshAction), for: .valueChanged)
        refresh.tintColor = UIColor.black
        collectionView?.alwaysBounceVertical = true
        
        collectionView?.insertSubview(refresh, at: 0)
        refresh.layer.zPosition = -1
    }
    
    func handleDataSourceUpdates() {
        dataSource.add(observer: self) {[weak self] dataSource in
            guard let this = self else { return }
            
            if dataSource.state == .loading {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            if dataSource.state == .done {
                this.collectionView?.reloadData()
                this.refresh.endRefreshing()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    @objc func pullToRefreshAction() {
        dataSource.loadIfNeeded()
    }
    
    fileprivate func isPortrait(_ orientation: UIInterfaceOrientation) -> Bool {
        return orientation == .portrait || orientation == .portraitUpsideDown
    }

    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        let layout = collectionViewLayout as! DynamicHeightLayout
        updateColumnsNumberForOrientation(isPortrait(toInterfaceOrientation))
        layout.invalidateLayout()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.lastValidData.data.count
    }

    var lastRandomColorIndex = -1
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! NewsCell
        
        //let color = dataSource.colors[indexPath.item]
        cell.contentView.backgroundColor = UIColor.white
        
        let current = dataSource.lastValidData.data[indexPath.item]
        
        cell.setup(current)
    
        return cell
    }

}

extension MainCVC: DynamicHeightLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, columnWidth: CGFloat, heightForItemAt indexPath: IndexPath) -> CGFloat {
        let current = dataSource.lastValidData.data[indexPath.item]
        let height = NewsCell.calculateHeightFor(current.title, detailsText: current.details, width: columnWidth)
        
        return height
    }
}
