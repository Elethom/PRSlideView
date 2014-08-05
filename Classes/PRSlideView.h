//
//  PRSlideView.h
//  PRSlideView
//
//  Created by Elethom Hunter on 8/4/14.
//  Copyright (c) 2014 Project Rhinestone. All rights reserved.
//

#import "PRSlideViewPage.h"

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

@interface PRSlideView : UIScrollView

@property (nonatomic, weak) id<PRSlideViewDelegate> delegate;
@property (nonatomic, weak) id<PRSlideViewDataSource> dataSource;

- (NSInteger)currentPageIndex;
- (NSInteger)numberOfPages;

- (id)dequeueReusablePageWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

- (void)registerClass:(Class)pageClass forPageReuseIdentifier:(NSString *)identifier;

- (PRSlideViewPage *)pageAtIndex:(NSInteger)index;
- (NSInteger)indexForPage:(PRSlideViewPage *)page;
- (NSArray *)visiblePages;

- (void)scrollToPageAtIndex:(NSInteger)index;
- (void)scrollToPageAtIndex:(NSInteger)index animated:(BOOL)animated;

- (void)reloadData;

@end
