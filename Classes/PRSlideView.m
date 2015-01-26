//
//  PRSlideView.m
//  PRSlideView
//
//  Created by Elethom Hunter on 8/4/14.
//  Copyright (c) 2014 Project Rhinestone. All rights reserved.
//

#import "PRSlideView.h"

@interface PRSlideView ()

@property (nonatomic, assign) NSInteger currentPageActualIndex;
@property (nonatomic, assign) NSInteger numberOfPages;
@property (nonatomic, assign) NSInteger baseIndexOffset;

@property (nonatomic, strong) NSMutableDictionary *classForIdentifiers;
@property (nonatomic, strong) NSMutableDictionary *reusablePages;
@property (nonatomic, strong) NSMutableArray *loadedPages;

@property (nonatomic, assign) BOOL isResizing;

- (void)addPagesAtIndexRange:(NSRange)indexRange;
- (void)removePagesOutOfIndexRange:(NSRange)indexRange;
- (void)didScrollToPageAtIndex:(NSInteger)index;

- (void)scrollToPageAtActualIndex:(NSInteger)index;
- (void)scrollToPageAtActualIndex:(NSInteger)index animated:(BOOL)animated;

- (NSInteger)actualIndexForIndexInCurrentLoop:(NSInteger)index;
- (NSInteger)actualIndexForIndex:(NSInteger)index forward:(BOOL)forward;
- (NSInteger)indexForActualIndex:(NSInteger)index;
- (CGRect)rectForPageAtIndex:(NSInteger)index;
- (void)resizeContent;

- (void)pageClicked:(PRSlideViewPage *)page;

- (void)setup;

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
    CGRect frame = [self rectForPageAtIndex:index];
    if (!reusablePage) {
        Class PRSlideViewPageClass = NSClassFromString(self.classForIdentifiers[identifier]);
        reusablePage = [[PRSlideViewPageClass alloc] initWithFrame:frame];
        reusablePage.pageIdentifier = identifier;
    } else {
        reusablePage.frame = frame;
    }
    reusablePage.pageIndex = index;
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
    [self scrollToPageAtActualIndex:[self actualIndexForIndexInCurrentLoop:index]
                           animated:animated];
}

- (void)scrollToPageAtIndex:(NSInteger)index forward:(BOOL)forward animated:(BOOL)animated
{
    NSInteger actualIndex = self.infiniteScrollingEnabled ? [self actualIndexForIndex:index forward:forward] : index;
    [self scrollToPageAtActualIndex:actualIndex
                           animated:animated];
}

- (void)scrollToPageAtActualIndex:(NSInteger)index
{
    [self scrollToPageAtActualIndex:index animated:YES];
}

- (void)scrollToPageAtActualIndex:(NSInteger)index animated:(BOOL)animated
{
    [self setContentOffset:[self rectForPageAtIndex:index].origin animated:animated];
}

#pragma mark - Data

- (void)reloadData
{
    [self removePagesOutOfIndexRange:NSMakeRange(0, 0)];
    
    self.numberOfPages = [self.dataSource numberOfPagesInSlideView:self];
    if (self.infiniteScrollingEnabled && !self.currentPageIndex) {
        [self scrollToPageAtActualIndex:self.baseIndexOffset animated:NO];
    } else {
        [self didScrollToPageAtIndex:self.currentPageActualIndex];
    }
}

- (void)addPagesAtIndexRange:(NSRange)indexRange
{
    if (!self.infiniteScrollingEnabled) {
        indexRange = NSIntersectionRange(indexRange, NSMakeRange(0, self.numberOfPages));
    }
    for (NSInteger pageIndex = indexRange.location; pageIndex < NSMaxRange(indexRange); pageIndex++) {
        if (![self pageAtIndex:pageIndex]) {
            PRSlideViewPage *page = [self.dataSource slideView:self pageAtIndex:[self indexForActualIndex:pageIndex]];
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
                                         UIViewAutoresizingFlexibleTopMargin |
                                         UIViewAutoresizingFlexibleHeight |
                                         UIViewAutoresizingFlexibleBottomMargin);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addSubview:page];
                });
            }
        }
    }
}

- (void)removePagesOutOfIndexRange:(NSRange)indexRange
{
    if (!self.infiniteScrollingEnabled) {
        indexRange = NSIntersectionRange(indexRange, NSMakeRange(0, self.numberOfPages));
    }
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
        [self.delegate slideView:self didScrollToPageAtIndex:[self indexForActualIndex:index]];
    }
    NSInteger offset = index == 0 ? 1 : 0;
    NSRange currentRange = NSMakeRange(index + offset - 1, 3 - offset);
    [self removePagesOutOfIndexRange:currentRange];
    [self addPagesAtIndexRange:currentRange];
}

#pragma mark - Frame

- (NSInteger)actualIndexForIndexInCurrentLoop:(NSInteger)index
{
    if (!self.infiniteScrollingEnabled) {
        return index;
    }
    return self.currentPageActualIndex - self.currentPageIndex + index;
}

- (NSInteger)actualIndexForIndex:(NSInteger)index forward:(BOOL)forward
{
    if (!self.infiniteScrollingEnabled) {
        return index;
    }
    NSInteger currentPageActualIndex = self.currentPageActualIndex;
    NSInteger currentPageIndex = self.currentPageIndex;
    NSInteger numberOfPages = self.numberOfPages;
    NSInteger offset = index - currentPageIndex;
    if (forward) {
        if (offset >= 0) {
            return currentPageActualIndex + offset;
        } else {
            return currentPageActualIndex + numberOfPages + offset;
        }
    } else {
        if (offset <= 0) {
            return currentPageActualIndex + offset;
        } else {
            return currentPageActualIndex - numberOfPages + offset;
        }
    }
}

- (NSInteger)indexForActualIndex:(NSInteger)index
{
    NSInteger numberOfPages = self.numberOfPages;
    if (self.infiniteScrollingEnabled && index && numberOfPages) {
        index = index % numberOfPages;
        if (index < 0) {
            index += numberOfPages;
        }
    }
    return index;
}

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
        BOOL infiniteScrollingEnabled = self.infiniteScrollingEnabled;
        NSInteger numberOfPages = self.numberOfPages;
        CGRect bounds = self.bounds;
        CGFloat width = CGRectGetWidth(bounds);
        CGFloat height = CGRectGetHeight(bounds);
        CGSize contentSize = CGSizeMake(direction == PRSlideViewDirectionHorizontal ? infiniteScrollingEnabled ? width * numberOfPages * 512 : width * numberOfPages : width,
                                        direction == PRSlideViewDirectionVertical ? infiniteScrollingEnabled ? height * numberOfPages * 512 : height * numberOfPages : height);
        self.contentSize = contentSize;
        for (PRSlideViewPage *page in self.visiblePages) {
            page.frame = [self rectForPageAtIndex:page.pageIndex];
        }
    });
}

#pragma mark - Actions

- (void)pageClicked:(PRSlideViewPage *)page
{
    if ([self.delegate respondsToSelector:@selector(slideView:didClickPageAtIndex:)]) {
        [self.delegate slideView:self didClickPageAtIndex:[self indexForActualIndex:page.pageIndex]];
    }
}

#pragma mark - Getters and setters

- (NSInteger)currentPageIndex
{
    return [self indexForActualIndex:self.currentPageActualIndex];
}

- (void)setCurrentPageActualIndex:(NSInteger)currentPageActualIndex
{
    if (_currentPageActualIndex != currentPageActualIndex) {
        _currentPageActualIndex = currentPageActualIndex;
        if (!self.isResizing) {
            [self didScrollToPageAtIndex:currentPageActualIndex];
        }
    }
}

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    if (_numberOfPages != numberOfPages) {
        _numberOfPages = numberOfPages;
        self.baseIndexOffset = self.infiniteScrollingEnabled ? numberOfPages * 256 : 0;
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
        NSInteger index = (NSInteger)(direction == PRSlideViewDirectionHorizontal ? (contentOffset.x + width * .5f) / width : (contentOffset.y + height * .5f) / height);
        self.currentPageActualIndex = index;
        super.contentOffset = contentOffset;
    }
}

- (void)setFrame:(CGRect)frame
{
    self.isResizing = YES;
    NSUInteger currentPageActualIndex = self.currentPageActualIndex;
    [super setFrame:frame];
    self.currentPageActualIndex = currentPageActualIndex;
    [self resizeContent];
    [self scrollToPageAtActualIndex:currentPageActualIndex animated:NO];
    self.isResizing = NO;
}

#pragma mark - Life cycle

- (void)setup
{
    self.pagingEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.clipsToBounds = NO;
    
    self.classForIdentifiers = [[NSMutableDictionary alloc] init];
    self.reusablePages = [[NSMutableDictionary alloc] init];
    self.loadedPages = [[NSMutableArray alloc] init];
    
    self.scrollsToTop = NO;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setup];
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
