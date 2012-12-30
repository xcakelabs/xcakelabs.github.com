#import "HazardMapViewController.h"

#import "HazardMap.h"
#import "HazardMapView.h"

@implementation HazardMapViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    // Find and load the earthquake hazard grid from the application's bundle
    NSString *hazardPath = [[NSBundle mainBundle] pathForResource:@"UShazard.20081229.pga.5pc50" ofType:@"bin"];
    HazardMap *hazards = [[HazardMap alloc] initWithHazardMapFile:hazardPath];
    
    // Position and zoom the map to just fit the grid loaded on screen
    [map setVisibleMapRect:[hazards boundingMapRect]];
    
    // Add the earthquake hazard map to the map view
    [map addOverlay:hazards];
    
    // Let the map view own the hazards model object now
    [hazards release];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay{
    HazardMapView *view = [[HazardMapView alloc] initWithOverlay:overlay];
    return [view autorelease];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return YES;
}

@end
