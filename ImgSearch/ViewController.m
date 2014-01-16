//
//  ViewController.m
//  ImgSearch
//
//  Created by Vishal Parikh on 11/12/13.
//  Copyright (c) 2013 Health Equity Labs. All rights reserved.
//

#import "ImageCell.h"
#import "MHFacebookImageViewer.h"
#import "MNMBottomPullToRefreshManager.h"
#import "UIImage+Decompression.h"
#import "ViewController.h"
#import <NHBalancedFlowLayout/NHBalancedFlowLayout.h>

@interface ViewController () <UICollectionViewDelegateFlowLayout, NHBalancedFlowLayoutDelegate,
MNMBottomPullToRefreshManagerClient, MHFacebookImageViewerDatasource>

@property (weak, nonatomic) IBOutlet UITextField *searchTermTextField;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *results;
@property (strong, nonatomic) NSMutableArray *images;
@property (strong, nonatomic) NSNumber *nextStartIndex;
@property (strong, nonatomic) NSOperationQueue *queue;
@property (strong, nonatomic) MNMBottomPullToRefreshManager *bottomRefreshManager;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _bottomRefreshManager = [[MNMBottomPullToRefreshManager alloc] initWithPullToRefreshViewHeight:60
                                                                                    collectionView:_collectionView
                                                                                        withClient:self];
    [_bottomRefreshManager setLoadingIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _queue = [[NSOperationQueue alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)didSearch:(UIButton *)sender {
    [_queue cancelAllOperations];
    [_queue waitUntilAllOperationsAreFinished];
    _images = [NSMutableArray array];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    _errorLabel.text = @""; // clear any previous errors
    [_searchTermTextField resignFirstResponder]; // hide keyboard

    [self loadPageFromIndex:@0];
}

- (void)loadNextPage:(id)sender
{
    [_bottomRefreshManager collectionViewReloadFinished];
    [self loadPageFromIndex:_nextStartIndex];
}

- (void)loadPageFromIndex:(NSNumber *)startIndex
{
    // https://developers.google.com/image-search/v1/jsondevguide#basic_query
    // Return 8 images per page (maximum per Google)
    NSString* encodedSearchText = [_searchTermTextField.text
                                   stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString *queryString = [NSString stringWithFormat:@"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&rsz=8&start=%@&q=%@",
                             startIndex, encodedSearchText];
    
    //Make an asynchronous request for the data
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:queryString]]
                                       queue:_queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (error) {
             _errorLabel.text = [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
         } else {
             NSError *localError = nil;
             NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
             
             if (localError != nil) {
                 _errorLabel.text = [NSString stringWithFormat:@"Error: Cannot parse result - %@",
                                     error.localizedDescription];
             }else{
                 //_nextStartIndex
                 NSDictionary *responseData = parsedObject[@"responseData"];
                 NSDictionary *cursor = responseData[@"cursor"];
                 NSArray* pages = cursor[@"pages"];
                 int currentPageIndex = [cursor[@"currentPageIndex"] intValue];
                 if ( pages.count <= currentPageIndex+1 ) {
                     // Reached end - API only allows to query up to 64 results (8 pages with 8 results each)
                     return;
                 }
                 _nextStartIndex = pages[currentPageIndex+1][@"start"];
                 _results = responseData[@"results"];
                 if ( ![_results isKindOfClass:[NSArray class]] || _results.count == 0 ) {
                     //                    _errorLabel.text = @"No results";
                 }
                 else {
                     // Load all images for this page
                     for( NSDictionary* imageDict in _results ) {
                         // NOTE: This is loading the high-res version of the image
                         // One could also use "tbUrl" but it is very low-res
                         NSString *image = imageDict[@"url"];
                         [self getImage:image];
                     }
                 }
             }
         }
         // Count 1 since operation will be removed after this block
         [UIApplication sharedApplication].networkActivityIndicatorVisible = (_queue.operationCount != 1);
     }];
}

-(void) getImage:(NSString *)url
{
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]]
                                       queue:_queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if(error){
             _errorLabel.text = @"Error retrieving image";
         }else{
             dispatch_async(dispatch_get_main_queue(), ^{
                 UIImage *img = [[UIImage alloc] initWithData:data];
                 if ( img ) {
                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                         [_images addObject:img];
                         // WORKAROUND: Apparently UICollectionView has a bug sometimes causing a crash when
                         // inserting the very first cell, see http://openradar.appspot.com/12954582
                         if ( _images.count == 1 ) {
                             [_collectionView reloadData];
                         }
                         else {
                             [_collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:_images.count-1 inSection:0]]];
                         }
                     }];
                 }
             });
         }
         // Count 1 since operation will be removed after this block
         [UIApplication sharedApplication].networkActivityIndicatorVisible = (_queue.operationCount != 1);
     }];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self didSearch:nil];
    return YES;
}

#pragma mark -
#pragma mark - UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(NHBalancedFlowLayout *)collectionViewLayout
preferredSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [_images[indexPath.item] size];
}

#pragma mark -
#pragma mark - UICollectionView data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    return _images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    cell.imageView.image = nil;
    
    [cell.imageView setupImageViewerWithDatasource:self initialIndex:indexPath.row onOpen:^{
    } onClose:^{
    }];
    
    // Decompress image on background thread before displaying it to prevent lag
    NSInteger rowIndex = indexPath.row;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        UIImage *image = [UIImage decodedImageWithImage:_images[indexPath.item]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *currentIndexPathForCell = [collectionView indexPathForCell:cell];
            if (currentIndexPathForCell.row == rowIndex) {
                cell.imageView.image = image;
            }
        });
    });
    
    return cell;
}

#pragma mark -
#pragma mark MHFacebookImageViewerDatasource

- (NSInteger) numberImagesForImageViewer:(MHFacebookImageViewer *)imageViewer {
    return _images.count;
}

- (UIImage*) imageDefaultAtIndex:(NSInteger)index imageViewer:(MHFacebookImageViewer *)imageViewer{
    return _images[index];
}

#pragma mark -
#pragma mark MNMBottomPullToRefreshManagerClient

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [_bottomRefreshManager collectionViewScrolled];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [_bottomRefreshManager collectionViewReleased];
}

- (void)bottomPullToRefreshTriggered:(MNMBottomPullToRefreshManager *)manager {
}

- (void)MNMBottomPullToRefreshManagerClientReloadCollectionView{
    
    [self performSelector:@selector(loadNextPage:) withObject:_bottomRefreshManager afterDelay:1];
}

@end
