//
//  PRSlideView.m
//  PRSlideView
//
//  Created by Elethom Hunter on 8/4/14.
//  Copyright (c) 2014 Project Rhinestone. All rights reserved.
//

#import "PRSlideView.h"

@interface PRSlideView ()

@property (nonatomic, assign) NSInteger currentPageIndex;
@property (nonatomic, assign) NSInteger numberOfPages;

@property (nonatomic, strong) NSMutableDictionary *classForIdentifiers;
@property (nonatomic, strong) NSMutableDictionary *reusablePages;
@property (nonatomic, strong) NSMutableArray *loadedPages;

@property (nonatomic, assign) BOOL isResizing;

- (void)addPagesAtIndexRange:(NSRange)indexRange;
- (void)removePagesOutOfIndexRange:(NSRange)indexRange;
- (void)didScrollToPageAtIndex:(NSInteger)index;

- (CGRect)rectForPageAtIndex:(NSInteger)index;
- (void)resizeContent;

- (void)pageClicked:(PRSlideViewPage *)page;

@end

@implementation PRSlideView

#pragma mark - Create pages

- (id)dequeueReusablePageWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index
{
    PRSlideViewPage *reusablePage;
    if ([self.reusablePages.allKeys containsObject:identifier]) {
        NSMutableSet *pages = self.reusablePages[identifier];
        if (pages.count) {
            reusablePage = pages.anyObject;
            [pages removeObject:reusablePage];
        }
    }
    if (!reusablePage) {
        Class PRSlideViewPageClass = NSClassFromString(self.classForIdentifiers[identifier]);
        reusablePage = [[PRSlideViewPageClass alloc] init];
        reusablePage.pageIdentifier = identifier;
    }
    reusablePage.pageIndex = index;
    reusablePage.frame = [self rectForPageAtIndex:index];
    [self.loadedPages addObject:reusablePage];
    return reusablePage;
}

- (void)registerClass:(Class)pageClass forPageReuseIdentifier:(NSString *)identifier
{
    self.classForIdentifiers[identifier] = NSStringFromClass(pageClass);
}

#pragma mark - Access pages

- (PRSlideViewPage *)pageAtIndex:(NSInteger)index
{
    __block PRSlideViewPage *page;
    [self.loadedPages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PRSlideViewPage *pageObject = obj;
        if (pageObject.pageIndex == index) {
            page = pageObject;
            *stop = YES;
        }
    }];
    return page;
}

- (NSInteger)indexForPage:(PRSlideViewPage *)page
{
    return page.pageIndex;
}

- (NSArray *)visiblePages
{
    return self.loadedPages;
}

#pragma mark - Scroll

- (void)scrollToPageAtIndex:(NSInteger)index
{
    [self scrollToPageAtIndex:index animated:YES];
}

- (void)scrollToPageAtIndex:(NSInteger)index animated:(BOOL)animated
{
    [self setContentOffset:[self rectForPageAtIndex:index].origin animated:animated];
}

#pragma mark - Data

- (void)reloadData
{
    [self removePagesOutOfIndexRange:NSMakeRange(0, 0)];
    
    self.numberOfPages = [self.dataSource numberOfPagesInSlideView:self];
    [self resizeContent];
    
    NSInteger basePageIndex = MIN(self.currentPageIndex, self.numberOfPages - 1);
    NSUInteger offset = basePageIndex == 0 ? 1 : 0;
    [self addPagesAtIndexRange:NSMakeRange(basePageIndex + offset - 1, 3 - offset)];
    
    [self didScrollToPageAtIndex:self.currentPageIndex];
}

- (void)addPagesAtIndexRange:(NSRange)indexRange
{
    indexRange = NSIntersectionRange(indexRange, NSMakeRange(0, self.numberOfPages));
    for (NSInteger pageIndex = indexRange.location; pageIndex < NSMaxRange(indexRange); pageIndex++) {
        if (![self pageAtIndex:pageIndex]) {
            PRSlideViewPage *page = [self.dataSource slideView:self pageAtIndex:pageIndex];
            [page addTarget:self action:@selector(pageClicked:) forControlEvents:UIControlEventTouchUpInside];
            if (page) {
                page.pageIndex = pageIndex;
                
                if (![self.loadedPages containsObject:page]) {
                    BOOL inserted = NO;
                    for (NSInteger targetIndex = 0; targetIndex < self.loadedPages.count; targetIndex++) {
                        PRSlideViewPage *targetPage = self.loadedPages[targetIndex];
                        if (targetPage.pageIndex > pageIndex) {
                            [self.loadedPages insertObject:page atIndex:targetIndex];
                            inserted = YES;
                            break;
                        }
                    }
                    if (!inserted) {
                        [self.loadedPages addObject:page];
                    }
                }
                
                page.frame = [self rectForPageAtIndex:pageIndex];
                page.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                         UIViewAutoresizingFlexibleWidth |
                                         UIViewAutoresizingFlexibleRightMargin |
                                         UIViewAutoresizingFlexibleHeight);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addSubview:page];
                });
            }
        }
    }
}

- (void)removePagesOutOfIndexRange:(NSRange)indexRange
{
    indexRange = NSIntersectionRange(indexRange, NSMakeRange(0, self.numberOfPages));
    for (NSInteger idx = 0; idx < self.loadedPages.count; idx++) {
        PRSlideViewPage *page = self.loadedPages[idx];
        NSInteger pageIndex = page.pageIndex;
        if (!NSLocationInRange(pageIndex, indexRange)) {
            NSString *pageIdentifier = page.pageIdentifier;
            NSMutableSet *pages;
            if ([self.reusablePages.allKeys containsObject:pageIdentifier]) {
                pages = self.reusablePages[pageIdentifier];
            } else {
                pages = [[NSMutableSet alloc] init];
                self.reusablePages[pageIdentifier] = pages;
            }
            [pages addObject:page];
            dispatch_async(dispatch_get_main_queue(), ^{
                [page removeFromSuperview];
            });
            [self.loadedPages removeObject:page];
            idx--;
        }
    }
}

- (void)didScrollToPageAtIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(slideView:didScrollToPageAtIndex:)]) {
        [self.delegate slideView:self didScrollToPageAtIndex:index];
    }
    NSInteger offset = index == 0 ? 1 : 0;
    NSRange currentRange = NSMakeRange(index + offset - 1, 3 - offset);
    [self removePagesOutOfIndexRange:currentRange];
    [self addPagesAtIndexRange:currentRange];
}

#pragma mark - Frame

- (CGRect)rectForPageAtIndex:(NSInteger)index
{
    PRSlideViewDirection direction = self.direction;
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    CGRect rect = CGRectMake(direction == PRSlideViewDirectionHorizontal ? width * index : 0,
                             direction == PRSlideViewDirectionVertical ? height * index : 0,
                             width,
                             height);
    return rect;
}

- (void)resizeContent
{
    dispatch_async(dispatch_get_main_queue(), ^{
        PRSlideViewDirection direction = self.direction;
        CGRect bounds = self.bounds;
        CGFloat width = CGRectGetWidth(bounds);
        CGFloat height = CGRectGetHeight(bounds);
        self.contentSize = CGSizeMake(width * (direction == PRSlideViewDirectionHorizontal ? self.numberOfPages : 1),
                                      height * (direction == PRSlideViewDirectionVertical ? self.numberOfPages : 1));
        for (PRSlideViewPage *page in self.visiblePages) {
            page.frame = [self rectForPageAtIndex:page.pageIndex];
        }
    });
}

#pragma mark - Actions

- (void)pageClicked:(PRSlideViewPage *)page
{
    if ([self.delegate respondsToSelector:@selector(slideView:didClickPageAtIndex:)]) {
        [self.delegate slideView:self didClickPageAtIndex:page.pageIndex];
    }
}

#pragma mark - Getters and setters

- (void)setCurrentPageIndex:(NSInteger)currentPageIndex
{
    if (_currentPageIndex != currentPageIndex) {
        _currentPageIndex = currentPageIndex;
        if (!self.isResizing) {
            [self didScrollToPageAtIndex:currentPageIndex];
        }
    }
}

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    if (_numberOfPages != numberOfPages) {
        _numberOfPages = numberOfPages;
        [self resizeContent];
    }
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    if (!CGPointEqualToPoint(self.contentOffset, contentOffset)) {
        PRSlideViewDirection direction = self.direction;
        CGRect bounds = self.bounds;
        CGFloat width = CGRectGetWidth(bounds);
        CGFloat height = CGRectGetHeight(bounds);
        self.currentPageIndex = direction == PRSlideViewDirectionHorizontal ? (contentOffset.x + width * .5f) / width : (contentOffset.y + height * .5f) / height;
        super.contentOffset = contentOffset;
    }
}

- (void)setFrame:(CGRect)frame
{
    self.isResizing = YES;
    NSUInteger currentPageIndex = self.currentPageIndex;
    [super setFrame:frame];
    self.currentPageIndex = currentPageIndex;
    [self resizeContent];
    [self scrollToPageAtIndex:currentPageIndex animated:NO];
    self.isResizing = NO;
}

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.pagingEnabled = YES;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.clipsToBounds = NO;
        
        self.classForIdentifiers = [[NSMutableDictionary alloc] init];
        self.reusablePages = [[NSMutableDictionary alloc] init];
        self.loadedPages = [[NSMutableArray alloc] init];
        
        self.scrollsToTop = NO;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
