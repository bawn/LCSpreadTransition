//
//  ViewController.m
//  LCSpreadTransition
//
//  Created by bawn on 12/31/15.
//  Copyright © 2015 bawn. All rights reserved.
//

#import "ViewController.h"
#import "ModelViewController.h"
#import "LCPinterestTransitionProtocol.h"
#import "LCSpreadTransitionAnimation.h"
#import "UICollectionView+IndexPath.h"

@interface ViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, LCPinterestControllerProtocol>

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) LCSpreadTransitionAnimation *animation;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

//- (void)viewWillAppear:(BOOL)animated{
//    [super viewWillAppear:animated];
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
//}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
//    if (indexPath.row == 0) {
        collectionView.selectedIndexPath = indexPath;
        ModelViewController *modelViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ModelViewController"];
            modelViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        self.animation = [[LCSpreadTransitionAnimation alloc] initWithModalViewController:modelViewController];
//        self.animation.bounces = NO;
        self.animation.dragable = YES;
        self.animation.behindViewAlpha = 0.8f;
        self.animation.behindViewScale = 0.95;
//        self.animation.transitionDuration = 0.35f;
        [self.animation setContentScrollView:modelViewController.scrollView];
        
        modelViewController.transitioningDelegate = self.animation;
        [self presentViewController:modelViewController animated:YES completion:NULL];
//        self.navigationController.delegate = self.animation;
//        [self.navigationController pushViewController:modelViewController animated:YES];
//    }
//    else{
//       
//        UIViewController *modelViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ModelViewController"];
//        modelViewController.view.backgroundColor = [UIColor whiteColor];
//        //    modelViewController.modalPresentationStyle = UIModalPresentationFullScreen;
////        self.animation = [[LCSpreadTransitionAnimation alloc] initWithModalViewController:modelViewController];
////        self.animation.bounces = NO;
////        self.animation.dragable = YES;
////        self.animation.behindViewAlpha = 0.8f;
////        self.animation.behindViewScale = 1;
////        self.animation.transitionDuration = 0.35f;
////        //    [self.animation setContentScrollView:commodityDetailViewController.tableView];
////        self.navigationController.delegate = self.animation;
//        self.navigationController.delegate = nil;
//        [self.navigationController pushViewController:modelViewController animated:YES];
//    }
}

- (UICollectionView *)collectionViewForTransition{
    return self.collectionView;
}

- (UIImageView *)snapShotViewForTransition{
    UIGraphicsBeginImageContextWithOptions(self.navigationController.view.frame.size, NO, [UIScreen mainScreen].scale);
    [self.navigationController.view drawViewHierarchyInRect:[UIScreen mainScreen].bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = [UIScreen mainScreen].bounds;
    return imageView;
}

@end
