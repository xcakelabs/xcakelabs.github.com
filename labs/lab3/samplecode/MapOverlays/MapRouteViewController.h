#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "DetailViewController.h"
#import "NimbleAppAppDelegate.h"

@class NimbleAppAppDelegate,CSWebDetailsViewController;
@class TourData,OverlayMap;

@interface MapRouteViewController : NimbleViewController  <MKMapViewDelegate> {
	
	BOOL displayRegionMonitor;
	
	NimbleAppAppDelegate *delegate;
	MKMapView *mapview;
	UIButton *titleButton;
	NSMutableDictionary* _routeViews;
	
	NSDictionary *routeDictionary;
	NSArray *allRoutesArray;
	NSArray *selectedRouteArray;
	NSArray *entriesArray;
	NSInteger selectedPOIIndex;

	NSArray* points;
	NSArray* selectedPoints;
	NSDictionary* pointsOfInterest;
	UIColor* lineColor;

	BOOL activeRoute;
	
	CGPoint endTouchPosition;
	BOOL canStartTour;
	NSArray *detailArray;
	
	BOOL drawRoutes;
	BOOL drawPoints;
	BOOL mapToOverlay;
	BOOL mapview_mapType_overlay;
		
	UIView *viewOverlayEditor;
	UITextField *textfieldN;
	UITextField *textfieldS;
	UITextField *textfieldW;
	UITextField *textfieldE;
	UITextField *textfieldRot;
	UIButton *buttonSubmitOverlayChanges;

	OverlayMap *overlayMap;
	OverlayMap *backgroundOverlayMap;
	
	MKCoordinateRegion allowedRegion;
	MKMapRect lastGoodRect;
	MKMapRect allowedMapRect;
	BOOL manuallyChangingMapRect;
	
	NSMutableArray *mutableArrayAllSegmentsAndPoints;
	NSMutableArray *mutableArraySelectedPoints;
	NSMutableArray *mutableArrayAllPoints;
	NSMutableArray *mutableArraySelectedSegmentsAndPoints;
    
    BOOL disableAccessoryButtonOnPoints;
	
}
@property (nonatomic, assign) MKCoordinateRegion allowedRegion;
@property (nonatomic,retain) OverlayMap *overlayMap;
@property (nonatomic,retain) OverlayMap *backgroundOverlayMap;

@property (nonatomic,retain) IBOutlet UIView *viewOverlayEditor;
@property (nonatomic,retain) IBOutlet UITextField *textfieldN;
@property (nonatomic,retain) IBOutlet UITextField *textfieldS;
@property (nonatomic,retain) IBOutlet UITextField *textfieldW;
@property (nonatomic,retain) IBOutlet UITextField *textfieldE;
@property (nonatomic,retain) IBOutlet UITextField *textfieldRot;
@property (nonatomic,retain) IBOutlet UIButton *buttonSubmitOverlayChanges;

@property (nonatomic,retain)  NimbleAppAppDelegate *delegate;
@property (nonatomic,retain) IBOutlet MKMapView *mapview;
@property (nonatomic,retain) UIButton *titleButton;
@property (nonatomic,retain) NSDictionary *routeDictionary;
@property (nonatomic,retain) NSArray *allRoutesArray;
@property (nonatomic,retain) NSArray *selectedRouteArray;
@property (nonatomic,retain) NSArray *entriesArray;

@property (nonatomic) NSInteger selectedPOIIndex;

@property (nonatomic, retain) NSArray* points;
@property (nonatomic, retain) NSDictionary* pointsOfInterest;
@property (nonatomic, retain) UIColor* lineColor;

@property (nonatomic, assign) BOOL activeRoute;

@property (nonatomic, assign) CGPoint endTouchPosition;

@property (nonatomic, assign) BOOL canStartTour;

@property (nonatomic, retain) NSArray *detailArray;

@property (nonatomic,assign) BOOL drawRoutes;
@property (nonatomic,assign) BOOL drawPoints;
@property (nonatomic,assign) BOOL mapToOverlay;

@property (nonatomic,retain) NSMutableArray *mutableArrayAllSegmentsAndPoints;
@property (nonatomic,retain) NSMutableArray *mutableArraySelectedPoints;
@property (nonatomic,retain) NSMutableArray *mutableArrayAllPoints;
@property (nonatomic,retain) NSMutableArray *mutableArraySelectedSegmentsAndPoints;

@property (nonatomic,assign) BOOL disableAccessoryButtonOnPoints;


-(void)showSelectedPin;
-(CLLocation*)locationFromDictionary:(NSDictionary*)dictionary;
//-(void)toggleMapHybrid;
-(IBAction)showPOIDetail:(id)sender;

-(void)clearMapOverlays;

//-(void)setupMapAnnotations;
//-(void)drawMapAnnotations;

//-(void)zoomInMapFurther;

-(void)confineMapToViewport:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;

-(void)setMapRegion:(MKCoordinateRegion)region animated:(BOOL)animated;
-(void)setMapRegionByItineraryCoordsSpan:(BOOL)animated;
-(void)restrictMapviewToAnnotationsWithAnimation:(BOOL)animated;
-(IBAction)logCurrentMapRegion;
-(void)setOuterMapRegion;
-(void)getDirections;

-(void)setMapRegionByEntryCoordsSpan:(BOOL)animated;

@end
