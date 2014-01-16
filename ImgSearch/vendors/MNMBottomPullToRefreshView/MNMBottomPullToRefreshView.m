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

#import "MNMBottomPullToRefreshView.h"

/**
 * Defines the localized strings table
 */
#define MNM_BOTTOM_PTR_LOCALIZED_STRINGS_TABLE                          @"MNMBottomPullToRefresh"

/**
 * Texts to show in different states
 */
#define kMessageLoading            @"Loading ..."
#define kMessageRelease            @"Release to load more ..."
#define kMessagePull               @"Pull up to load more ..."

/**
 * Defines arrow image
 */
#define MNM_BOTTOM_PTR_ARROW_BOTTOM_IMAGE                        @"img_pullrefresh_arrowup.png"

@implementation MNMBottomPullToRefreshView

@dynamic isLoading;
@synthesize loadingActivityIndicator = loadingActivityIndicator_;

#pragma mark -
#pragma mark Memory management

/**
 * Deallocates used memory
 */
- (void)dealloc {
    arrowImageView_ = nil;
    loadingActivityIndicator_ = nil;
    messageLabel_ = nil;
    
}

#pragma mark -
#pragma mark Initialization

/**
 * Initializes and returns a newly allocated view object with the specified frame rectangle.
 *
 * @param aRect: The frame rectangle for the view, measured in points.
 * @return An initialized view object or nil if the object couldn't be created.
 */
- (id)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor clearColor];
        
        UIImage *arrowImage = [UIImage imageNamed:MNM_BOTTOM_PTR_ARROW_BOTTOM_IMAGE];
        
        arrowImageView_ = [[UIImageView alloc] initWithFrame:CGRectMake(30.0f, round(CGRectGetHeight(frame) / 2.0f) - round(arrowImage.size.height / 2.0f), arrowImage.size.width, arrowImage.size.height)];
        arrowImageView_.contentMode = UIViewContentModeCenter;
        arrowImageView_.image = arrowImage;
        
        [self addSubview:arrowImageView_];
        
        loadingActivityIndicator_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        loadingActivityIndicator_.center = arrowImageView_.center;
        loadingActivityIndicator_.hidesWhenStopped = YES;
        
        [self addSubview:loadingActivityIndicator_];
        
        messageLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(arrowImageView_.frame) + 20.0f, 10.0f, CGRectGetWidth(frame) - CGRectGetMaxX(arrowImageView_.frame) - 40.0f, CGRectGetHeight(frame) - 20.0f)];
        messageLabel_.backgroundColor = [UIColor clearColor];
        messageLabel_.textColor = [UIColor blackColor];
    
        [self addSubview:messageLabel_];
        
        rotateArrowWhileBecomingVisible_ = YES;
        
        [self changeStateOfControl:MNMBottomPullToRefreshViewStateIdle withOffset:CGFLOAT_MAX];
        
    }
    
    return self;
}

#pragma mark -
#pragma mark Visuals

/*
 * Changes the state of the control depending on state_ value
 */
- (void)changeStateOfControl:(MNMBottomPullToRefreshViewState)state withOffset:(CGFloat)offset {
    
    state_ = state;
    
    switch (state_) {
        
        case MNMBottomPullToRefreshViewStateIdle: {
            
            arrowImageView_.transform = CGAffineTransformIdentity;
            arrowImageView_.hidden = NO;
            
            [loadingActivityIndicator_ stopAnimating];
            
            messageLabel_.text = kMessagePull;
            
            break;
            
        } case MNMBottomPullToRefreshViewStatePull: {
            
            if (rotateArrowWhileBecomingVisible_) {
                
                if (!CGAffineTransformEqualToTransform(arrowImageView_.transform, CGAffineTransformIdentity)) {
                    if (!CGAffineTransformEqualToTransform(arrowImageView_.transform, CGAffineTransformIdentity)) {
                        [UIView animateWithDuration:0.25f
                                              delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState
                                         animations:^{
                                             arrowImageView_.transform = CGAffineTransformIdentity;
                                         }
                                         completion:nil];
                    }
                }
            } else {
            
                arrowImageView_.transform = CGAffineTransformIdentity;
            }
            
            messageLabel_.text = kMessagePull;
            
            break;
            
        } case MNMBottomPullToRefreshViewStateRelease: {
            [UIView animateWithDuration:0.25f
                                  delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 arrowImageView_.transform = CGAffineTransformMakeRotation(M_PI);
                             }
                             completion:nil];
            messageLabel_.text = kMessageRelease;
            break;
            
        } case MNMBottomPullToRefreshViewStateLoading: {
            
            arrowImageView_.hidden = YES;
            
            [loadingActivityIndicator_ startAnimating];
            
            messageLabel_.text = kMessageLoading;
            
            break;
            
        } default:
            break;
    }
}

#pragma mark -
#pragma mark Properties

/**
 * Returns state of activity indicator
 *
 * @return YES if activity indicator is animating
 */
- (BOOL)isLoading {
    return loadingActivityIndicator_.isAnimating;
}


- (MNMBottomPullToRefreshViewState)getState
{
    return state_;
}

@end
