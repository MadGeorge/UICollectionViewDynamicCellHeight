import UIKit

class MainCVC: UICollectionViewController {

    let dataSource = RemoteDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup required delegate for custom layout
        let layout = collectionViewLayout as! DynamicHeightLayout
        layout.delegate = self
        
        updateColumnsNumberForOrientation(isPortrait(UIApplication.sharedApplication().statusBarOrientation))
        
        setupPullToRefreshControl()
        
        handleDataSourceUpdates()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if dataSource.state == .Initialised {
            collectionView?.setContentOffset(CGPoint(x: 0, y:  collectionView!.contentOffset.y - refresh.frame.size.height), animated: true)
            refresh.beginRefreshing()
            pullToRefreshAction()
        }
    }
    
    // We want to display different number of columns for big and small screens and different orientations
    func updateColumnsNumberForOrientation(isPortrait: Bool) {
        let layout = collectionViewLayout as! DynamicHeightLayout
        print(traitCollection.verticalSizeClass.rawValue, traitCollection.horizontalSizeClass.rawValue)
        let isBig = traitCollection.verticalSizeClass == .Regular && traitCollection.horizontalSizeClass == .Regular
        let columnsCountNarrow = isBig ? 2 : 1
        let columnsCountWidth = isBig ? 3 : 2
        layout.numberOfColumns = isPortrait ? columnsCountNarrow : columnsCountWidth
    }
    
    private var refresh = UIRefreshControl()
    func setupPullToRefreshControl() {
        refresh.addTarget(self, action: #selector(pullToRefreshAction), forControlEvents: .ValueChanged)
        refresh.tintColor = UIColor.blackColor()
        collectionView?.alwaysBounceVertical = true
        
        collectionView?.insertSubview(refresh, atIndex: 0)
        refresh.layer.zPosition = -1
    }
    
    func handleDataSourceUpdates() {
        dataSource.add(observer: self) {[weak self] dataSource in
            guard let this = self else { return }
            
            if dataSource.state == .Loading {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            }
            
            if dataSource.state == .Done {
                this.collectionView?.reloadData()
                this.refresh.endRefreshing()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
    }
    
    @objc func pullToRefreshAction() {
        dataSource.loadIfNeeded()
    }
    
    private func isPortrait(orientation: UIInterfaceOrientation) -> Bool {
        return orientation == .Portrait || orientation == .PortraitUpsideDown
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let layout = collectionViewLayout as! DynamicHeightLayout
        updateColumnsNumberForOrientation(isPortrait(toInterfaceOrientation))
        layout.invalidateLayout()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.lastValidData.data.count
    }

    var lastRandomColorIndex = -1
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! NewsCell
        
        //let color = dataSource.colors[indexPath.item]
        cell.contentView.backgroundColor = UIColor.whiteColor()
        
        let current = dataSource.lastValidData.data[indexPath.item]
        
        cell.setup(current)
    
        return cell
    }

}

extension MainCVC: DynamicHeightLayoutDelegate {
    func collectionView(collectionView: UICollectionView, columnWidth: CGFloat, heightForItemAt indexPath: NSIndexPath) -> CGFloat {
        let current = dataSource.lastValidData.data[indexPath.item]
        let height = NewsCell.calculateHeightFor(current.title, detailsText: current.details, width: columnWidth)
        
        return height
    }
}