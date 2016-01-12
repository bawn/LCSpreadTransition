//
//  UICollectionView+IndexPath.m
//  LCDragableModalTransition
//
//  Created by bawn on 12/28/15.
//  Copyright © 2015 bawn. All rights reserved.
//

#import "UICollectionView+IndexPath.h"
#import <objc/runtime.h>

static void *LCCollectionViewIndexPathKey = &LCCollectionViewIndexPathKey;

@implementation UICollectionView (IndexPath)

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath{
    objc_setAssociatedObject(self, LCCollectionViewIndexPathKey, selectedIndexPath, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSIndexPath *)selectedIndexPath{
    return objc_getAssociatedObject(self, LCCollectionViewIndexPathKey);
}


@end


