//
//  LCPinterestTransitionProtocol.h
//  LCDragableModalTransition
//
//  Created by bawn on 12/27/15.
//  Copyright © 2015 bawn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol LCPinterestControllerProtocol <NSObject>

@required

- (UICollectionView *)collectionViewForTransition;
- (UIImageView *)snapShotViewForTransition;

@end


@protocol LCPinterestCellProtocol <NSObject>

@required

//- (UIView *)snapShotViewForTransition;

@end

