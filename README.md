# UICollectionView cell dynamic height with custom multicolumn layout

This project provide example how to implement multicolumn multilie layout for UICollectionView

<p align="center">
<img src="https://github.com/MadGeorge/UICollectionViewDynamicCellHeight/raw/master/ReadmeResources/screencast-ipad.gif"/> 
<img src="https://github.com/MadGeorge/UICollectionViewDynamicCellHeight/raw/master/ReadmeResources/screencast-iphone.gif"/>
</p>


# Requirements

- Swift 3, Xcode 8.2+, AutoLayout
- Minimum iOS version is 8.2

For Swift 2.3 see related branch

# How to use

This is example project and you should not care most of the sources. 

You only interested in `DynamicHeightLayout.swift` as layout implementation and in `MainCVC.swift` and `NewsCell.swift` as usage example.

1. Drop `DynamicHeightLayout.swift` into your project
2. Implement `DynamicHeightLayoutDelegate`
3. Set DynamicHeightLayout as custom layout class for your collection view controller in storyboard or from code
4. Provide delegate for `DynamicHeightLayout`

    ```
    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = collectionViewLayout as! DynamicHeightLayout
        layout.delegate = self
    }
    ```

5. Calculate height of each cell and return it when `DynamicHeightLayoutDelegate` will ask

# Tips

Look at the `MainCVC.swift` for setup example

Example how to calculate height for cell with multilined labels in `NewCell.swift`

# Perfomance

It should be fast, as soon as `DynamicHeightLayout` fill out its cache for UICollectionViewLayoutAttributes. 
