#import <QuartzCore/QuartzCore.h>
#import "MapRouteViewController.h"
#import "CSMapAnnotation.h"
#import "CSPinAnnotationView.h"
#import "CSImageAnnotationView.h"
#import "CSWebDetailsViewController.h"
#import "CSRouteAnnotation.h"
#import "CSRouteView.h"
#import "OverlayMap.h"
#import "OverlayMapView.h"
#import "TileOverlay.h"
#import "TileOverlayView.h"
#import "ReminderAnnotation.h"
#import "ReminderCircleView.h"

#import "NimbleApp.h"
#import "Tour.h"
#import "TourManager.h"

#import "ItineraryInitialViewportCoordinates.h"
#import "ItineraryInitialViewportSpan.h"
#import "ItineraryViewportCoordinates.h"
#import "ItineraryViewportSpan.h"

#import "TourManager.h"
#import "PageManager.h"
#import "EntryManager.h"
#import "Page.h"
#import "Entry.h"

@implementation MapRouteViewController

@synthesize allowedRegion;
@synthesize delegate;
//@synthesize mapview = _mapView;
@synthesize mapview;
@synthesize titleButton;
@synthesize routeDictionary;
@synthesize allRoutesArray;
@synthesize selectedRouteArray;
@synthesize entriesArray;
@synthesize selectedPOIIndex;
@synthesize points;
@synthesize pointsOfInterest;
@synthesize lineColor;
@synthesize activeRoute;
@synthesize endTouchPosition;
@synthesize canStartTour;
@synthesize detailArray;
@synthesize drawRoutes;
@synthesize drawPoints;
@synthesize mapToOverlay;
@synthesize overlayMap;
@synthesize backgroundOverlayMap;

@synthesize viewOverlayEditor,textfieldN,textfieldS,textfieldW,textfieldE,textfieldRot,buttonSubmitOverlayChanges;
@synthesize mutableArrayAllSegmentsAndPoints,mutableArraySelectedPoints,mutableArrayAllPoints,mutableArraySelectedSegmentsAndPoints;

@synthesize disableAccessoryButtonOnPoints;

NSString * const GMAP_ANNOTATION_SELECTED = @"gmapselected";
NSString * const GMAP_OVERLAY_NONE = @"Offline";
NSString * const GMAP_OVERLAY_MAPOVERLAY = @"Online";

-(void)loadTilesForMap{
	// Initialize the TileOverlay with tiles in the application's bundle's resource directory.
    // Any valid tiled image directory structure in there will do.
    NSString *tileDirectory = [[NimbleUtils getCurrentBundlePath] stringByAppendingPathComponent:@"Tiles"];
	
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:tileDirectory];
	if (fileExists){
		TileOverlay *overlay = [[TileOverlay alloc] initWithTileDirectory:tileDirectory];
		[mapview addOverlay:overlay];
        [overlay release];

		// zoom in by a factor of two from the rect that contains the bounds
		// because MapKit always backs up to get to an integral zoom level so
		// we need to go in one so that we don't end up backed out beyond the
		// range of the TileOverlay.
		MKMapRect visibleRect = [mapview mapRectThatFits:overlay.boundingMapRect];
		visibleRect.size.width /= 2;
		visibleRect.size.height /= 2;
		visibleRect.origin.x += visibleRect.size.width / 2;
		visibleRect.origin.y += visibleRect.size.height / 2;
		mapview.visibleMapRect = visibleRect;
		
	}
}

#pragma mark standard ViewController methods
-(void)viewDidLoad{
	[super viewDidLoad];
    
	displayRegionMonitor = [[[NimbleUtils app] displayRegionMonitor] boolValue];
	
	//basic setup	
	//navbar button setup
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(handleBack:)];
	self.navigationItem.leftBarButtonItem.accessibilityLabel = @"Back";
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:GMAP_OVERLAY_MAPOVERLAY style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMapHybrid)];
	
	UIView *titleView = self.navigationController.navigationBar;
	titleButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	[titleButton addTarget:self action:@selector(logCurrentMapRegion) forControlEvents:UIControlEventTouchUpInside];
	[titleButton setFrame:CGRectMake(120, 0, titleView.frame.size.width-240, titleView.frame.size.height)];
	[titleButton setBounds:titleButton.frame];
	[titleView addSubview:titleButton];
	
	_routeViews = [[NSMutableDictionary alloc] init];
	
	//setup & populate mutableArrays for selected/all points & routes
	mutableArrayAllSegmentsAndPoints = [[NSMutableArray alloc] init];
	mutableArraySelectedPoints = [[NSMutableArray alloc] init];
	mutableArrayAllPoints = [[NSMutableArray alloc] init];
	mutableArraySelectedSegmentsAndPoints = [[NSMutableArray alloc] init];
	for (NSArray* routes in allRoutesArray)
		for (NSArray * segments in routes){
			NSMutableArray *mutableSegmentArray = [[NSMutableArray alloc] init];
			for (NSDictionary *point in segments)
				[mutableSegmentArray addObject:[self locationFromDictionary:point]];
			[mutableArrayAllSegmentsAndPoints addObject:mutableSegmentArray];
			[mutableSegmentArray release];
		}
	for (NSArray* segment in selectedRouteArray){
		NSMutableArray *mutableSegmentArray = [[NSMutableArray alloc] init];
		for (NSDictionary * point in segment){
			[mutableSegmentArray addObject:[self locationFromDictionary:point]];
			[mutableArraySelectedPoints addObject:[self locationFromDictionary:point]];
		}
		[mutableArraySelectedSegmentsAndPoints addObject:mutableSegmentArray];
		[mutableSegmentArray release];
	}
	
	[self loadTilesForMap];
	
	//draw routes next
	if (drawRoutes){
		//all routes
		for (NSArray* segment in mutableArrayAllSegmentsAndPoints){
			CSRouteAnnotation *routeAnnotation = [[[CSRouteAnnotation alloc] initWithPoints:segment] autorelease];
			if(nil != routeAnnotation.points && routeAnnotation.points.count > 0){
				CLLocationCoordinate2D coords[routeAnnotation.points.count];
				for(CLLocation* location in routeAnnotation.points)
					coords[[routeAnnotation.points indexOfObject:location]] = location.coordinate;
				MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords count:[routeAnnotation.points count]];
				self.lineColor = [[UIColor redColor] colorWithAlphaComponent:0.66];
				[mapview addOverlay:polyline];
			}
		}
		
		//the selected route
		for (NSArray* segment in mutableArraySelectedSegmentsAndPoints){
			CSRouteAnnotation *routeAnnotation = [[[CSRouteAnnotation alloc] initWithPoints:segment] autorelease];
			if(nil != routeAnnotation.points && routeAnnotation.points.count > 0){
				CLLocationCoordinate2D coords[routeAnnotation.points.count];
				for(CLLocation* location in routeAnnotation.points){
					coords[[routeAnnotation.points indexOfObject:location]] = location.coordinate;
					[mutableArrayAllPoints addObject:location];
				}
				MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords count:[routeAnnotation.points count]];
				self.lineColor = [[UIColor purpleColor] colorWithAlphaComponent:0.66]; 
				[mapview addOverlay:polyline];
			}
		}
	}
	
	//draw points last
	if (drawPoints){
		//add pin annotations for entries
		for (Entry *entry in entriesArray) {
			NSString *title = [entry name];
	 		NSString *subtitle = [entry shortDescription];
			CLLocation *location = [NimbleUtils locationFromGPSCoords:[entry gPSCoords]];
			CLLocationDistance radius = [[entry zoneRadius] intValue];
			
			CSMapAnnotation* annotation = [[[CSMapAnnotation alloc] initWithCoordinate:location.coordinate
																	   annotationType:CSMapAnnotationTypeEnd
																				title:title
																			 subtitle:subtitle] autorelease];
			[annotation setRadius:radius];
			[annotation setTag:[entriesArray indexOfObject:entry]];
			[mapview deselectAnnotation:annotation animated:NO];
			[mapview addAnnotation:annotation];
			
			if (displayRegionMonitor){
				CLLocationDistance radius = [[entry zoneRadius] intValue];
				ReminderAnnotation *anno = [ReminderAnnotation reminderWithCoordinate:location.coordinate radius:radius];
				//[mapview addAnnotation:anno];
				[mapview addOverlay:anno];
			}
			
		}
		
		for (Entry *entry in entriesArray) {
			CLLocation *location = [NimbleUtils locationFromGPSCoords:[entry gPSCoords]];
			[mutableArrayAllPoints addObject:location];
		}
	}
    
    //Show Directions button if only one point
    if ([entriesArray count] == 1)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Directions" style:UIBarButtonItemStyleBordered target:self action:@selector(getDirections)];
    }
	
}

-(void)setMapRegionByEntryCoordsSpan:(BOOL)animated{
    Entry *entry = [TourManager currentEntry];
    
    EntryGPSCoords *viewCrds = [entry viewportCoordinates];
	EntryGPSCoords *viewSpan = [entry viewportSpan];
    if (viewCrds!=nil && viewSpan!=nil){
		CLLocationCoordinate2D routeViewportCoordinates = CLLocationCoordinate2DMake([[viewCrds lat] floatValue], 
																					 [[viewCrds lon] floatValue]);
		MKCoordinateSpan routeViewportSpan = MKCoordinateSpanMake([[viewSpan lat] floatValue],
																  [[viewSpan lon] floatValue]);
		MKCoordinateRegion region = MKCoordinateRegionMake(routeViewportCoordinates,
                                                           routeViewportSpan);
        if (!(region.center.latitude==0 && region.center.longitude==0)){
            manuallyChangingMapRect = YES;
            [mapview setRegion:region animated:animated];
            allowedRegion = region;
            manuallyChangingMapRect = NO;
        }
    }
    
}
-(void)setMapRegionByItineraryCoordsSpan:(BOOL)animated{
	Tour *tour = [TourManager tour];
    
    ItineraryViewportCoordinates *viewCrds = [tour viewportCoordinates];
	ItineraryViewportSpan *viewSpan = [tour viewportSpan];
    if (viewCrds!=nil && viewSpan!=nil){
		CLLocationCoordinate2D routeViewportCoordinates = CLLocationCoordinate2DMake([[viewCrds lat] floatValue], 
																					 [[viewCrds lon] floatValue]);
		MKCoordinateSpan routeViewportSpan = MKCoordinateSpanMake([[viewSpan lat] floatValue],
																  [[viewSpan lon] floatValue]);
		MKCoordinateRegion region = MKCoordinateRegionMake(routeViewportCoordinates,
                                                           routeViewportSpan);
        if (!(region.center.latitude==0 && region.center.longitude==0)){
            manuallyChangingMapRect = YES;
            [mapview setRegion:region animated:animated];
            allowedRegion = region;
            manuallyChangingMapRect = NO;
        }
    }
    
	ItineraryInitialViewportCoordinates *initialViewCrds = [tour initialViewportCoordinates];
	ItineraryInitialViewportSpan *initialViewSpan = [tour initialViewportSpan];

	if (initialViewCrds!=nil && initialViewSpan!=nil){
		CLLocationCoordinate2D routeViewportCoordinates = CLLocationCoordinate2DMake([[initialViewCrds lat] floatValue], 
																					 [[initialViewCrds lon] floatValue]);
		MKCoordinateSpan routeViewportSpan = MKCoordinateSpanMake([[initialViewSpan lat] floatValue],
																  [[initialViewSpan lon] floatValue]);
		MKCoordinateRegion region = MKCoordinateRegionMake(routeViewportCoordinates,
										routeViewportSpan);
        if (!(region.center.latitude==0 && region.center.longitude==0)){
            manuallyChangingMapRect = YES;
            [mapview setRegion:region animated:animated];
            allowedRegion = region;
            manuallyChangingMapRect = NO;
        }
	}
}

-(void)setMapRegion:(MKCoordinateRegion)region animated:(BOOL)animated{
	//	//NSLog(@"\n%s    region = %f, %f, %f, %f",__FUNCTION__,region.center.latitude,region.center.longitude,region.span.latitudeDelta,region.span.longitudeDelta);
	if (!(region.center.latitude==0 && region.center.longitude==0)){
		manuallyChangingMapRect = YES;
		[mapview setRegion:region animated:animated];
		allowedRegion = region;
		manuallyChangingMapRect = NO;
	}
	lastGoodRect = mapview.visibleMapRect;
}

-(void)setInitialMapRegion:(BOOL)animated{
	MKCoordinateRegion region = [NimbleUtils getDefaultInitialMapViewport];
//	NSLog(@"%s\nregion = %f, %f, %f, %f",__FUNCTION__,region.center.latitude,region.center.longitude,region.span.latitudeDelta,region.span.longitudeDelta);
	if (!(region.center.latitude==0 && region.center.longitude==0)){
		manuallyChangingMapRect = YES;
		[mapview setRegion:region animated:animated];
		allowedRegion = region;
		manuallyChangingMapRect = NO;
	}
	lastGoodRect = mapview.visibleMapRect;
}
-(void)setOuterMapRegion{
	MKCoordinateRegion region = [NimbleUtils getDefaultMapViewport];
//	NSLog(@"%s\nregion = %f, %f, %f, %f",__FUNCTION__,region.center.latitude,region.center.longitude,region.span.latitudeDelta,region.span.longitudeDelta);
	if (!(region.center.latitude==0 && region.center.longitude==0)){
		manuallyChangingMapRect = YES;
		[mapview setRegion:region animated:NO];
		allowedRegion = region;
		manuallyChangingMapRect = NO;
	} else {
		[self restrictMapviewToAnnotationsWithAnimation:NO];
	}
	allowedMapRect = mapview.visibleMapRect;
}

-(void) resetPositionOnEnterBack {
	[self setOuterMapRegion];
	Tour *tour = [TourManager tour];
    Entry *entry = [TourManager currentEntry];
    if ([entry viewportCoordinates] && [entry viewportSpan]){
        [self setMapRegionByEntryCoordsSpan:NO];
        return;
    }
	if ([tour viewportCoordinates] && [tour viewportSpan]){
		[self setMapRegionByItineraryCoordsSpan:NO];
        return;
    }
    [self setInitialMapRegion:NO];
}	
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	//show the nav bar always, hide the tool bar always
	[[self navigationController] setNavigationBarHidden:NO];
	[[self navigationController] setToolbarHidden:YES animated:NO];
	//[mapview setShowsUserLocation:YES];
	// Dermot Daly: Note: if you just call the resetPosition, the map will not have its region correct
	// This appears to be caused by some funniness carried out by UIKit which resets the map region when we are going back
	// Not sure why.
	// We put the resetPosition stuff in viewDidAppear, and though it worked, it led to a screen flicker.
	// This way, it still appears to work before viewDidAppear, but doesn't suffer the UIKit weirdness.
	[self performSelector:@selector(resetPositionOnEnterBack) withObject:nil afterDelay:0.1];
	
}
-(void)showSelectedPin{
    KIFCommand(@"[scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@\"%@\"]];", @"pin");
	NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
	for (MKAnnotationView *annotation in [mapview annotations])
		if ([annotation isKindOfClass:[CSMapAnnotation class]]){
			[mapview deselectAnnotation:(CSMapAnnotation*)annotation animated:YES];
			[mutableArray addObject:annotation];
		}
	if ([mutableArray count]>0 && selectedPOIIndex!=-1){
		CSMapAnnotation *annotation = [mutableArray objectAtIndex:selectedPOIIndex];
		for (CSMapAnnotation *annotation in mutableArray)
			[mapview deselectAnnotation:annotation animated:YES];
		[mapview selectAnnotation:annotation animated:YES];
	}
	[mutableArray release];
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return 
	(interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || 
	(interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

-(void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(void)viewDidUnload{
    [super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    self.viewOverlayEditor		    = nil;
    self.textfieldN				    = nil;
    self.textfieldS				    = nil;
    self.textfieldW				    = nil;
    self.textfieldE				    = nil;
    self.textfieldRot			    = nil;
    self.buttonSubmitOverlayChanges = nil;
}
-(void)dealloc{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self selector:@selector(mapView:regionDidChangeAnimated:) object:nil];
	mapview.delegate = nil;
	[mapview release];
	[_routeViews release];
    [super dealloc];
}

#pragma mark mapView delegate functions
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	////NSLog(@"touching?");
	UITouch *touch = [touches anyObject];
	endTouchPosition = [touch locationInView:self.view];
	if (!CGRectContainsPoint(mapview.annotationVisibleRect, endTouchPosition)){
		////NSLog(@"we got touched!");
	}
}

#pragma mark mapView annotation functions
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
	MKAnnotationView* annotationView = nil;
	if (!drawPoints)
		return nil;

	if([annotation isKindOfClass:[CSMapAnnotation class]]){
		// determine the type of annotation, and produce the correct type of annotation view for it.
		CSMapAnnotation* csAnnotation = (CSMapAnnotation*)annotation;
		if(csAnnotation.annotationType == CSMapAnnotationTypeStart || csAnnotation.annotationType == CSMapAnnotationTypeEnd){
			NSString* identifier = @"Pin";
			CSPinAnnotationView* pin = (CSPinAnnotationView*)[mapview dequeueReusableAnnotationViewWithIdentifier:identifier];
			
			if(nil == pin)
				pin = [[[CSPinAnnotationView alloc] initWithAnnotation:csAnnotation reuseIdentifier:identifier] autorelease];
			[pin setPinColor:MKPinAnnotationColorGreen];
            if (!disableAccessoryButtonOnPoints){
                UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
                [rightButton addTarget:self action:@selector(showPOIDetail:) forControlEvents:UIControlEventTouchUpInside];
                [rightButton setTag:[csAnnotation tag]];
                pin.rightCalloutAccessoryView = rightButton;
                [pin.rightCalloutAccessoryView setAccessibilityLabel:@"accessory"];
            }
            [pin setAccessibilityLabel:@"pin"];
			pin.animatesDrop = YES;
            pin.canShowCallout = YES;
			annotationView = pin;
						
		}
		else if(csAnnotation.annotationType == CSMapAnnotationTypeImage){
			NSString* identifier = @"Image";
			
			CSImageAnnotationView* imageAnnotationView = (CSImageAnnotationView*)[mapview dequeueReusableAnnotationViewWithIdentifier:identifier];
			if(nil == imageAnnotationView){
				imageAnnotationView = [[[CSImageAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier] autorelease];	
				imageAnnotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			}
			annotationView = imageAnnotationView;
		}
		[annotationView setEnabled:YES];
		[annotationView setCanShowCallout:YES];
	}
	
	else if([annotation isKindOfClass:[CSRouteAnnotation class]]){
		CSRouteAnnotation* routeAnnotation = (CSRouteAnnotation*) annotation;
		annotationView = [_routeViews objectForKey:routeAnnotation.routeID];
		if(nil == annotationView){
			CSRouteView* routeView = [[[CSRouteView alloc] initWithFrame:CGRectMake(0, 0, mapview.frame.size.width, mapview.frame.size.height)] autorelease];
			routeView.annotation = routeAnnotation;
			routeView.mapView = mapview;
			[_routeViews setObject:routeView forKey:routeAnnotation.routeID];
			annotationView = routeView;
		}
	}
	for(NSObject* key in [_routeViews allKeys]){
		CSRouteView* routeView = [_routeViews objectForKey:key];
		routeView.hidden = NO;
		[routeView regionChanged];
	}		
	return annotationView;
}
-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay{

	if ([overlay isKindOfClass:[ReminderAnnotation class]]) {
		if (displayRegionMonitor){
			MKOverlayView *result = nil;
			result = [[ReminderCircleView alloc] initWithReminder:(ReminderAnnotation *)overlay];
			[(MKOverlayPathView *)result setFillColor:[[NimbleUtils getInstance].defaultNavColor colorWithAlphaComponent:0.2]];
			[(MKOverlayPathView *)result setStrokeColor:[[NimbleUtils getInstance].defaultNavColor colorWithAlphaComponent:0.7]];
			[(MKOverlayPathView *)result setLineWidth:4.0];
			return [result autorelease];
		}
	}
	
	UIColor *activeRouteColor = [[NimbleUtils getInstance].activeRouteColor colorWithAlphaComponent:0.9];
	if ([overlay isKindOfClass:[TileOverlay class]]){
		TileOverlayView *view = [[TileOverlayView alloc] initWithOverlay:overlay];
		[view setMinZoomLevel:[(TileOverlay*)overlay minZoomLevel]];
		[view setMaxZoomLevel:[(TileOverlay*)overlay maxZoomLevel]];
		view.tileAlpha = 1.0;
		return [view autorelease];
	} else if ([overlay isKindOfClass:[MKPolygon class]]) {
		if (!drawRoutes)
			return nil;
		MKPolygonView*	aView = [[MKPolygonView alloc] initWithPolygon:(MKPolygon*)overlay];
		aView.strokeColor = activeRouteColor;
		aView.lineWidth = 4;
		return [aView autorelease];
	} else if ([overlay isKindOfClass:[MKPolyline class]]) {
		if (!drawRoutes)
			return nil;
		MKPolylineView* aView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
		aView.strokeColor = activeRouteColor;
		aView.lineWidth = 6;
		return [aView autorelease];
	} else if ([overlay isKindOfClass:[OverlayMap class]]){
		OverlayMapView *aView = [[OverlayMapView alloc] initWithOverlay:overlay];
		aView.mapView = mapview;
		[aView setOpacity:1.0];
		OverlayMap *map = overlay;
		aView.image = map.image;
		aView.upperLeftCoord = map.upperLeftCoord;
		aView.lowerRightCoord = map.lowerRightCoord;
		aView.rotationDegrees = map.rotationDegrees;
		CALayer *layer = aView.layer;
		[layer setShadowOffset:CGSizeMake(-1.0, -3.0)];
		[layer setShadowColor:[UIColor blackColor].CGColor];
		[layer setShadowOpacity:0.5];
		return [aView autorelease];
	}
	return nil;
}

#pragma mark Drawing methods
-(CLLocation*)locationFromDictionary:(NSDictionary*)dictionary{
	return [[[CLLocation alloc] initWithLatitude:[[dictionary objectForKey:@"lat"] floatValue]
									   longitude:[[dictionary objectForKey:@"lon"] floatValue]] autorelease];
}
//-(void)toggleMapHybrid{
//	if (mapview_mapType_overlay) {
//		self.navigationItem.rightBarButtonItem.title = GMAP_OVERLAY_NONE;
//		mapview_mapType_overlay = NO;
//		[self clearMapOverlays];
//	} else {
//		self.navigationItem.rightBarButtonItem.title = GMAP_OVERLAY_MAPOVERLAY;
//		mapview_mapType_overlay = YES;
//		[self drawMapOverlay];
//		[self setInitialMapRegion:YES];
//	}
//}

#pragma mark override all HUD controls for the map view controller

-(void)clearMapOverlays{
	[self.viewOverlayEditor removeFromSuperview];
	
	NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
	for (id <MKOverlay> overlay in [mapview overlays]){
		if ([overlay isKindOfClass:[OverlayMap class]]){
			[mutableArray addObject:overlay];
		}
	}
	[mapview removeOverlays:mutableArray];
	[mutableArray release];
}

#pragma mark mapView delegate functions
-(void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
	if (manuallyChangingMapRect)
		return;
	lastGoodRect = mapView.visibleMapRect;
	// turn off the view of the route as the map is chaning regions. This prevents
	// the line from being displayed at an incorrect positoin on the map during the
	// transition. 
	for(NSObject* key in [_routeViews allKeys]){
		CSRouteView* routeView = [_routeViews objectForKey:key];
		routeView.hidden = YES;
	}
}
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
	// re-enable and re-poosition the route display. 
	if (manuallyChangingMapRect)
		return;
	
	for(NSObject* key in [_routeViews allKeys]){
		CSRouteView* routeView = [_routeViews objectForKey:key];
		routeView.hidden = NO;
		[routeView regionChanged];
	}
	
//	[self confineMapToViewport:mapView regionDidChangeAnimated:YES];
	return;
}
-(void)confineMapToViewport:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
//	//NSLog(@"%s",__FUNCTION__);
	if(mapview_mapType_overlay){
		BOOL overlayRegionContainsVisibleMapRegion = MKMapRectContainsRect(allowedMapRect, mapView.visibleMapRect);
		if (!overlayRegionContainsVisibleMapRegion) {
			manuallyChangingMapRect = YES;
			//			if (allowedMapRect.size.width <= mapView.visibleMapRect.size.width) {		
			//				[mapView setVisibleMapRect:allowedMapRect animated:animated];
			//			} else {			
			[mapView setVisibleMapRect:lastGoodRect animated:animated];
			//			}
			manuallyChangingMapRect = NO;
		}
	}
}

-(void)restrictMapviewToAnnotationsWithAnimation:(BOOL)animated{
	if ([mutableArrayAllPoints count]>1) {
		CSRouteAnnotation* selectedRouteAnnotation = [[CSRouteAnnotation alloc] initWithPoints:mutableArrayAllPoints];
		MKCoordinateRegion region = selectedRouteAnnotation.region;
		manuallyChangingMapRect = YES;
		[mapview setRegion:region animated:animated];
		manuallyChangingMapRect = NO;
		[selectedRouteAnnotation release];
		allowedRegion = region;
		allowedMapRect = mapview.visibleMapRect;
		lastGoodRect = allowedMapRect;
	}
}
-(IBAction)logCurrentMapRegion{
//    NSLog(@"%s",__FUNCTION__);
//	[NimbleUtils logCurrentMapRegion:mapview];
}

-(IBAction)showPOIDetail:(id)sender{
    KIFCommand(@"[scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@\"%@\"]];", @"accessory");
	UIButton *buttonPressed = sender;
	NSInteger poiIndex = [buttonPressed tag];	

//    NSArray *entries = [TourManager entries];
			
    Entry *entry = [entriesArray objectAtIndex:poiIndex];
    [EntryManager setEntry:entry];
    NSArray *pages = [[entry storyBoard] pages];
    [PageManager setPages:pages];
    [PageManager setPageTitleFromEntry:entry];
    Page *page = [pages objectAtIndex:0];
	NSString *contentNibName = [page contentType];
	DetailViewController *controller = [[DetailViewController alloc] initWithNibName:contentNibName bundle:nil];
    [controller setHudMenuKey:kvcHUDMenuPointOfInterestDetail];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}


-(void)getDirections{
    
    Entry *entry = [entriesArray objectAtIndex:0];
    [EntryManager setEntry:entry];
    
    DetailViewController *controller = [[DetailViewController alloc] initWithNibName:nil bundle:nil];
    [controller getDirections];
	[controller release];
}

@end



