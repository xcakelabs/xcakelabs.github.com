#import "HazardMapViewController.h"

//#import "OverlayMap.h"
//#import "OverlayMapView.h"
#import "TileOverlay.h"
#import "TileOverlayView.h"

@implementation HazardMapViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    [self loadTilesForMap];
}

- (MKOverlayView *)mapView:(MKMapView *)mv viewForOverlay:(id <MKOverlay>)overlay {
	if ([overlay isKindOfClass:[TileOverlay class]]){
		TileOverlayView *view = [[[TileOverlayView alloc] initWithOverlay:overlay] autorelease];
		[view setMinZoomLevel:[(TileOverlay*)overlay minZoomLevel]];
		[view setMaxZoomLevel:[(TileOverlay*)overlay maxZoomLevel]];
		return view;
    }
    return nil;
}

-(void)loadTilesForMap{
	// Initialize the TileOverlay with tiles in the application's bundle's resource directory.
    // Any valid tiled image directory structure in there will do.
    NSString *tileDirectory = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Tiles"];
 	
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:tileDirectory];
	if (fileExists){
		TileOverlay *overlay = [[TileOverlay alloc] initWithTileDirectory:tileDirectory];
		[map addOverlay:overlay];
        [overlay release];
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(53.345261,-6.264009);
        MKCoordinateSpan span = MKCoordinateSpanMake(0.003689,0.010300);
        MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
        [map setRegion:region animated:YES];
		
	}
}

@end
