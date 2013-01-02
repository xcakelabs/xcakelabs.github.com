#import <MapKit/MapKit.h>

@interface TileOverlayView : MKOverlayView {
    CGFloat tileAlpha;
	NSInteger minZoomLevel;
	NSInteger maxZoomLevel;
}

@property (nonatomic, assign) CGFloat tileAlpha;
@property (nonatomic, assign) NSInteger minZoomLevel;
@property (nonatomic, assign) NSInteger maxZoomLevel;

@end
