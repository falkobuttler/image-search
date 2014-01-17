//
//  ViewController.m
//  ImgSearch
//
//  Created by Vishal Parikh on 11/12/13.
//  Copyright (c) 2013 Health Equity Labs. All rights reserved.
//

#import "FilterViewController.h"
#import "ImageCell.h"
#import "MHFacebookImageViewer.h"
#import "MNMBottomPullToRefreshManager.h"
#import "SearchConfiguration.h"
#import "UIImage+Decompression.h"
#import "ViewController.h"
#import <RNBlurModalView/RNBlurModalView.h>
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
@property (strong, nonatomic) FilterViewController *filterViewController;

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
    
    _filterViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FilterViewController"];
    _filterViewController.view.frame = CGRectMake(0, 0, 260, 350);
    _filterViewController.view.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8f];
    _filterViewController.view.layer.borderColor = [UIColor whiteColor].CGColor;
    _filterViewController.view.layer.borderWidth = 2.f;
    _filterViewController.view.layer.cornerRadius = 10.f;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSearch:)
                                                 name:kRNBlurDidHidewNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)didSearch:(UIButton *)sender {
    if ( _searchTermTextField.text.length < 1 ) {
        return;
    }
    [_bottomRefreshManager setPullToRefreshViewVisible:YES];
    [_queue cancelAllOperations];
    [_queue waitUntilAllOperationsAreFinished];
    _images = [NSMutableArray array];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    _errorLabel.text = @""; // clear any previous errors
    [_searchTermTextField resignFirstResponder]; // hide keyboard

    _nextStartIndex = @0;
    [self loadNextPage:self];
}

- (IBAction)showFilter:(id)sender
{
    RNBlurModalView *modal = [[RNBlurModalView alloc] initWithViewController:self view:_filterViewController.view];
    [modal show];
}

- (void)loadNextPage:(id)sender
{
    [_bottomRefreshManager collectionViewReloadFinished];
    NSString* searchURL = [self generateGoogleImageSearchURL];
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:searchURL]]
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
                     [_bottomRefreshManager setPullToRefreshViewVisible:NO];
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

- (NSString*)generateGoogleImageSearchURL
{
    // https://developers.google.com/image-search/v1/jsondevguide#basic_query
    // Return 8 images per page (maximum per Google)
    NSString* encodedSearchText = [_searchTermTextField.text
                                   stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSMutableString *queryString = [[NSString stringWithFormat:@"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&rsz=8&start=%@&q=%@",
                                     _nextStartIndex, encodedSearchText] mutableCopy];
    
    SearchConfiguration* config = [SearchConfiguration sharedInstance];
    switch (config.fileTypes) {
        case SCFileTypesJPG:
            [queryString appendString:@"&as_filetype=jpg"];
            break;
        case SCFileTypesPNG:
            [queryString appendString:@"&as_filetype=png"];
            break;
        case SCFileTypesGIF:
            [queryString appendString:@"&as_filetype=gif"];
            break;
        case SCFileTypesBMP:
            [queryString appendString:@"&as_filetype=bmp"];
            break;
        case SCFileTypesAll:
        default:
            break;
    }
    switch (config.colors) {
        case SCColorsBlack:
            [queryString appendString:@"&imgcolor=black"];
            break;
        case SCColorsBlue:
            [queryString appendString:@"&imgcolor=blue"];
            break;
        case SCColorsBrown:
            [queryString appendString:@"&imgcolor=brown"];
            break;
        case SCColorsGray:
            [queryString appendString:@"&imgcolor=gray"];
            break;
        case SCColorsGreen:
            [queryString appendString:@"&imgcolor=green"];
            break;
        case SCColorsOrange:
            [queryString appendString:@"&imgcolor=orange"];
            break;
        case SCColorsPink:
            [queryString appendString:@"&imgcolor=pink"];
            break;
        case SCColorsPurple:
            [queryString appendString:@"&imgcolor=purple"];
            break;
        case SCColorsRed:
            [queryString appendString:@"&imgcolor=red"];
            break;
        case SCColorsTeal:
            [queryString appendString:@"&imgcolor=teal"];
            break;
        case SCColorsWhite:
            [queryString appendString:@"&imgcolor=white"];
            break;
        case SCColorsYellow:
            [queryString appendString:@"&imgcolor=yellow"];
            break;
        case SCColorsAll:
        default:
            break;
    }
    switch (config.rights) {
        case SCRightsPublicDomain:
            [queryString appendString:@"&as_rights=cc_publicdomain"];
            break;
        case SCRightsAttribute:
            [queryString appendString:@"&as_rights=cc_attribute"];
            break;
        case SCRightsSharealike:
            [queryString appendString:@"&as_rights=cc_sharealike"];
            break;
        case SCRightsNonCommercial:
            [queryString appendString:@"&as_rights=cc_noncommercial"];
            break;
        case SCRightsNonDerived:
            [queryString appendString:@"&as_rights=cc_nonderived"];
            break;
        case SCRightsAll:
        default:
            break;
    }
    switch (config.sizes) {
        case SCSizesIcon:
            [queryString appendString:@"&imgsz=icon"];
            break;
        case SCSizesSmall:
            [queryString appendString:@"&imgsz=small"];
            break;
        case SCSizesMedium:
            [queryString appendString:@"&imgsz=medium"];
            break;
        case SCSizesLarge:
            [queryString appendString:@"&imgsz=large"];
            break;
        case SCSizesXLarge:
            [queryString appendString:@"&imgsz=xlarge"];
            break;
        case SCSizesXXLarge:
            [queryString appendString:@"&imgsz=xxlarge"];
            break;
        case SCSizesHuge:
            [queryString appendString:@"&imgsz=huge"];
            break;
        case SCSizesAll:
        default:
            break;
    }
    switch (config.imageTypes) {
        case SCImageTypesFace:
            [queryString appendString:@"&imgtype=face"];
            break;
        case SCImageTypesPhoto:
            [queryString appendString:@"&imgtype=photo"];
            break;
        case SCImageTypesClipart:
            [queryString appendString:@"&imgtype=clipart"];
            break;
        case SCImageTypesLineart:
            [queryString appendString:@"&imgtype=lineart"];
            break;
        case SCImageTypesAll:
        default:
            break;
    }
    return queryString;
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
