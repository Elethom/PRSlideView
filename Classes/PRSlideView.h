//
//  PRSlideView.h
//  PRSlideView
//
//  Created by Elethom Hunter on 8/4/14.
//  Copyright (c) 2014 Project Rhinestone. All rights reserved.
//

#import "PRSlideViewPage.h"

extern CGFloat const kPRSlideViewPageControlHeight;

typedef NS_ENUM(NSUInteger, PRSlideViewDirection) {
    PRSlideViewDirectionHorizontal,
    PRSlideViewDirectionVertical
};

@class PRSlideView;

@protocol PRSlideViewDelegate <UIScrollViewDelegate>

@optional

- (void)slideView:(PRSlideView *)slideView didScrollToPageAtIndex:(NSInteger)index;

- (void)slideView:(PRSlideView *)slideView didClickPageAtIndex:(NSInteger)index;

@end

@protocol PRSlideViewDataSource <NSObject>

@required

- (NSInteger)numberOfPagesInSlideView:(PRSlideView *)slideView;
- (PRSlideViewPage *)slideView:(PRSlideView *)slideView pageAtIndex:(NSInteger)index;

@end

@interface PRSlideView : UIView

@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly) UIPageControl *pageControl;

@property (nonatomic, weak) id<PRSlideViewDelegate> delegate;
@property (nonatomic, weak) id<PRSlideViewDataSource> dataSource;

@property (nonatomic, assign) PRSlideViewDirection direction;
@property (nonatomic, assign) BOOL infiniteScrollingEnabled;
@property (nonatomic, assign) BOOL showsPageControl;

- (NSInteger)currentPageIndex;
- (NSInteger)numberOfPages;

- (__kindof PRSlideViewPage *)dequeueReusablePageWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

- (void)registerClass:(Class)pageClass forPageReuseIdentifier:(NSString *)identifier;

- (PRSlideViewPage *)pageAtIndex:(NSInteger)index;
- (NSInteger)indexForPage:(PRSlideViewPage *)page;
- (NSArray *)visiblePages;

- (void)scrollToPageAtIndex:(NSInteger)index;
- (void)scrollToPageAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)scrollToPageAtIndex:(NSInteger)index forward:(BOOL)forward animated:(BOOL)animated;

- (void)reloadData;

@end
