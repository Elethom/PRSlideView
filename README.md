# PRSlideView

[![Cocoapods](https://cocoapod-badges.herokuapp.com/v/PRSlideView/badge.png)](http://cocoapods.org/?q=PRSlideView)

## General

Slide view with gracefully written UIKit-like methods, delegate and data source protocol. Infinite scrolling supported.

Note: Auto layout not supported due to the special behaviours of `UIScrollView`. Please use autoresizing mask instead or wrap it with a container view.

## Installation

### With CocoaPods

In your `Podfile`:

```
pod 'PRSlideView'
```

## Usage

### Create a Slide View

```
PRSlideView *slideView = [[PRSlideView alloc] initWithFrame:self.view.bounds];
slideView.delegate = self;
slideView.dataSource = self;
slideView.direction = PRSlideViewDirectionHorizontal; // horizontal by default
slideView.infiniteScrollingEnabled = YES; // disabled by default
[slideView registerClass:PRAlbumPage.class
  forPageReuseIdentifier:NSStringFromClass(PRAlbumPage.class)];
slideView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                              UIViewAutoresizingFlexibleHeight);
self.slideView = slideView;
[self.view addSubview:slideView];
```

### Create a Slide View Page Subclass

```
#import "PRSlideViewPage.h"

@interface PRAlbumPage : PRSlideViewPage

@property (nonatomic, weak) UIImageView *coverImageView;

@end
```

```
#import "PRAlbumPage.h"

@implementation PRAlbumPage

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *coverImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        coverImageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleHeight);
        coverImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.coverImageView = coverImageView;
        [self addSubview:coverImageView];
    }
    return self;
}
```

### Use Data Source

```
#pragma mark - PRSlideViewDataSource

- (NSInteger)numberOfPagesInSlideView:(PRSlideView *)slideView
{
    return self.albumData.count;
}

- (PRSlideViewPage *)slideView:(PRSlideView *)slideView pageAtIndex:(NSInteger)index
{
    PRAlbumPage *page = [slideView dequeueReusablePageWithIdentifier:NSStringFromClass(PRAlbumPage.class)
                                                            forIndex:index];
    
    NSString *imageName = [self.albumData[index] stringByAppendingPathExtension:@"jpg"];
    page.coverImageView.image = [UIImage imageNamed:imageName];
    
    return page;
}
```

### Use Delegate

```
#pragma mark - PRSlideViewDelegate

- (void)slideView:(PRSlideView *)slideView didScrollToPageAtIndex:(NSInteger)index
{
    self.titleLabel.text = self.albumData[index];
}

- (void)slideView:(PRSlideView *)slideView didClickPageAtIndex:(NSInteger)index
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You clicked an album"
                                                    message:self.albumData[index]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
```

All done! You can check out the code in the demo provided.

## License

This code is distributed under the terms and conditions of the [MIT license](http://opensource.org/licenses/MIT).

## Donate

You can support me by:

* sending me iTunes Gift Cards;
* via [Alipay](https://www.alipay.com): elethomhunter@gmail.com
* via [PayPal](https://www.paypal.com): elethomhunter@gmail.com

:-)

## Contact

* [Telegram](https://telegram.org): [@elethom](http://telegram.me/elethom)
* [Email](mailto:elethomhunter@gmail.com)
* [Twitter](https://twitter.com/elethomhunter)
* [Blog](http://blog.projectrhinestone.org)

