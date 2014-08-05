//
//  PRAlbumPage.m
//  PRSlideViewExample
//
//  Created by Elethom Hunter on 8/5/14.
//  Copyright (c) 2014 Project Rhinestone. All rights reserved.
//

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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
