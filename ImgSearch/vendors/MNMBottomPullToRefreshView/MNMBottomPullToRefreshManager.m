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

#import "MNMBottomPullToRefreshManager.h"
#import "MNMBottomPullToRefreshView.h"

@interface MNMBottomPullToRefreshManager() 

@property (nonatomic, strong) CallbackBlock block;

/**
 * Returns the correct offset to apply to the pull-to-refresh view, depending on contentSize
 *
 * @return The offset
 * @private
 */
- (CGFloat)collectionViewScrollOffset;

@end

@implementation MNMBottomPullToRefreshManager
@synthesize block;


#pragma mark -
#pragma mark Memory management

/**
 * Deallocates not used memory
 */
- (void)dealloc {
    pullToRefreshView_ = nil;
    [collection_ removeObserver:self forKeyPath:@"contentOffset" context:nil];
    [collection_ removeObserver:self forKeyPath:@"contentSize" context:nil];
    collection_ = nil;
}

#pragma mark -
#pragma mark Instance initialization

/**
 * Implemented by subclasses to initialize a new object (the receiver) immediately after memory for it has been allocated.
 *
 * @return nil because that instance must be initialized with custom constructor
 */
- (id)init {
    return nil;
}

/*
 * Initializes the manager object with the information to link view and collection view
 */
- (id)initWithPullToRefreshViewHeight:(CGFloat)height collectionView:(UICollectionView *)collection withClient:(id<MNMBottomPullToRefreshManagerClient>)client {

    if (self = [super init]) {
        
        client_ = client;
        
        collection_ = collection;
        
        [collection_ addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [collection_ addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
        pullToRefreshView_ = [[MNMBottomPullToRefreshView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(collection_.frame), height)];
        
        [self relocatePullToRefreshView];
        
        [collection_ reloadData];
        [self collectionViewReloadFinished];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        
        if (!collection_.dragging && collection_.decelerating && [pullToRefreshView_ getState] == MNMBottomPullToRefreshViewStateRelease) {
             [self collectionViewReleased];
        } else {
            [self collectionViewScrolled];
        }
    } else if ([keyPath isEqualToString:@"contentSize"]) {
        [self relocatePullToRefreshView];
    }
}


- (id)initWithPullToRefreshViewHeight:(CGFloat)height collectionView:(UICollectionView *)collection
{
    if (self = [super init]) {
        collection_ = collection;
        [collection_ addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [collection_ addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
        pullToRefreshView_ = [[MNMBottomPullToRefreshView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(collection_.frame), height)];
        [self relocatePullToRefreshView];
        [collection_ reloadData];
        [self collectionViewReloadFinished];
    }
    
    return self;
}

#pragma mark -
#pragma mark Visuals

/*
 * Returns the correct offset to apply to the pull-to-refresh view, depending on contentSize
 */
- (CGFloat)collectionViewScrollOffset {
    
    CGFloat offset = 0.0f;        
    
    if (collection_.contentSize.height < collection_.frame.size.height) {
        
        offset = -collection_.contentOffset.y;
        
    } else {
        
        offset = (collection_.contentSize.height - collection_.contentOffset.y) - collection_.frame.size.height;
    }
    
    return offset;
}

/*
 * Relocate pull-to-refresh view
 */
- (void)relocatePullToRefreshView {
    [pullToRefreshView_ removeFromSuperview];
    CGFloat yCoord = 0.0f;
    
    if (collection_.contentSize.height >= collection_.frame.size.height) {
        
        yCoord = collection_.contentSize.height;
        
    } else {
        
        yCoord = collection_.frame.size.height;
    }
    
    CGRect frame = pullToRefreshView_.frame;
    frame.origin.y = yCoord;
    pullToRefreshView_.frame = frame;
    
    [collection_ addSubview:pullToRefreshView_];
}

/*
 * Sets the pull-to-refresh view visible or not. Visible by default
 */
- (void)setPullToRefreshViewVisible:(BOOL)visible {
    pullToRefreshView_.hidden = !visible;
}

-(void)setLoadingIndicatorStyle:(UIActivityIndicatorViewStyle)style{
    pullToRefreshView_.loadingActivityIndicator.activityIndicatorViewStyle = style;
}

#pragma mark -
#pragma mark Collection view scroll management

/*
 * Checks state of control depending on collection view scroll offset
 */
- (void)collectionViewScrolled {
    
    if (!pullToRefreshView_.hidden && !pullToRefreshView_.isLoading) {
        CGFloat offset = [self collectionViewScrollOffset];
        CGFloat height = -CGRectGetHeight(pullToRefreshView_.frame);
        if (offset <= 0.0f && offset >= height) {
            [pullToRefreshView_ changeStateOfControl:MNMBottomPullToRefreshViewStatePull withOffset:offset];
            
        } else {
            
            [pullToRefreshView_ changeStateOfControl:MNMBottomPullToRefreshViewStateRelease withOffset:CGFLOAT_MAX];
        }
    }
}

/*
 * Checks releasing of the collectionView
 */
- (void)collectionViewReleased {
    
    if (!pullToRefreshView_.hidden && !pullToRefreshView_.isLoading) {
        
        CGFloat offset = [self collectionViewScrollOffset];
        CGFloat height = -CGRectGetHeight(pullToRefreshView_.frame);
        
        if (offset <= 0.0f && offset < height) {
            
            [client_ MNMBottomPullToRefreshManagerClientReloadCollectionView];
            
            [pullToRefreshView_ changeStateOfControl:MNMBottomPullToRefreshViewStateLoading withOffset:CGFLOAT_MAX];
            
            [UIView animateWithDuration:0.5f animations:^{
                
                if (collection_.contentSize.height >= collection_.frame.size.height) {
                
                    collection_.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, -height, 0.0f);
                    
                } else {
                    
                    collection_.contentInset = UIEdgeInsetsMake(height, 0.0f, 0.0f, 0.0f);
                }
            }];
            
            if (self.block) {
                self.block();
            }
            
        }
    }
}

/*
 * The reload of the collection view is completed
 */
- (void)collectionViewReloadFinished {
    
    collection_.contentInset = UIEdgeInsetsZero;
    
    [self relocatePullToRefreshView];
        
    [pullToRefreshView_ changeStateOfControl:MNMBottomPullToRefreshViewStateIdle withOffset:CGFLOAT_MAX];
}

/*********************************************************************************/
#pragma mark - Custom Methods
/*********************************************************************************/

- (void)collectionViewReloadFinishedWithBlock:(void(^)(void))callbackBlock
{
    [self collectionViewReloadFinished];
    if (callbackBlock) {
        callbackBlock();
    }
}

- (void)setCallBackBlock:(CallbackBlock)callbackBlock
{
    self.block = callbackBlock;
}

@end