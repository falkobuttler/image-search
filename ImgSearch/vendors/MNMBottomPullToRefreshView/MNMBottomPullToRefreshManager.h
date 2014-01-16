/*
 * Copyright (c) 2012 Mario Negro Martín
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */

@class MNMBottomPullToRefreshView;
@class MNMBottomPullToRefreshManager;

#import <Foundation/Foundation.h>


typedef void(^CallbackBlock)(void);

/**
 * Delegate protocol to implement by MNMBottomPullToRefreshManager observers
 */
@protocol MNMBottomPullToRefreshManagerClient

/**
 * This is the same delegate method of UIScrollViewDelegate but requiered on MNMBottomPullToRefreshManagerClient protocol
 * to warn about its implementation. Here you have to call [MNMBottomPullToRefreshManager collectionViewScrolled]
 *
 * Tells the delegate when the user scrolls the content view within the receiver.
 *
 * @param scrollView: The scroll-view object in which the scrolling occurred.
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

/**
 * This is the same delegate method of UIScrollViewDelegate but requiered on MNMBottomPullToRefreshClient protocol
 * to warn about its implementation. Here you have to call [MNMBottomPullToRefreshManager collectionViewReleased]
 *
 * Tells the delegate when dragging ended in the scroll view.
 *
 * @param scrollView: The scroll-view object that finished scrolling the content view.
 * @param decelerate: YES if the scrolling movement will continue, but decelerate, after a touch-up gesture during a dragging operation.
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;

/**
 * Tells client that can reload collection view
 * After reloading is completed must call [MNMBottomPullToRefreshManager collectionViewReloadFinished]
 */
- (void)MNMBottomPullToRefreshManagerClientReloadCollectionView;

@end

#pragma mark -

/**
 * Manager that plays Mediator role and manages relationship between pull-to-refresh view and its associated collection view.
 */
@interface MNMBottomPullToRefreshManager : NSObject {
@private
    /**
     * Pull-to-refresh view
     */    
    MNMBottomPullToRefreshView *pullToRefreshView_;
    
    /**
     * collection view which p-t-r view will be added
     */
    UICollectionView *collection_;
    
    /**
     * Client object that observes changes
     */
    id<MNMBottomPullToRefreshManagerClient> client_;
}

/**
 * Initializes the manager object with the information to link view and collection view
 *
 * @param height The height that the pull-to-refresh view will have
 * @param collection Collection view to link pull-to-refresh view to
 * @param client The client that will observe behavior
 */
- (id)initWithPullToRefreshViewHeight:(CGFloat)height collectionView:(UICollectionView *)collection withClient:(id<MNMBottomPullToRefreshManagerClient>)client;

/**
 * Relocate pull-to-refresh view
 */
- (void)relocatePullToRefreshView;

/**
 * Sets the pull-to-refresh view visible or not. Visible by default.
 *
 * @param visible Visibility flag
 */
- (void)setPullToRefreshViewVisible:(BOOL)visible;

-(void)setLoadingIndicatorStyle:(UIActivityIndicatorViewStyle)style;

/**
 * Checks state of control depending on collection view scroll offset
 */
- (void)collectionViewScrolled;

/**
 * Checks releasing of the collection view
 */
- (void)collectionViewReleased;

/**
 * The reload of the collection view is completed
 */
- (void)collectionViewReloadFinished;


- (void)collectionViewReloadFinishedWithBlock:(void(^)(void))callback;

- (id)initWithPullToRefreshViewHeight:(CGFloat)height collectionView:(UICollectionView *)collection;

- (void)setCallBackBlock:(CallbackBlock)callbackBlock;

@end
