#import "TileOverlayView.h"
#import "TileOverlay.h"

@implementation TileOverlayView

@synthesize tileAlpha;
@synthesize minZoomLevel, maxZoomLevel;

- (id)initWithOverlay:(id <MKOverlay>)overlay{
    if ((self = [super initWithOverlay:overlay])) {
        tileAlpha = 0.75;
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}
- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale{

//	never used
//	CGFloat realScale = zoomScale / [[UIScreen mainScreen] scale];
    
    TileOverlay *tileOverlay = (TileOverlay *)self.overlay;
    NSArray *tilesInRect = [tileOverlay tilesInMapRect:mapRect zoomScale:zoomScale];
    return [tilesInRect count] > 0;    
}
- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context{
    
    // OverZoom Mode - Detect when we are zoomed beyond the tile set.
    NSInteger z = [TileOverlay zoomScaleToZoomLevel:zoomScale];
    NSInteger overZoom = 1;
    NSInteger zoomCap = maxZoomLevel;
	
    if (z > zoomCap) {
        // overZoom progression: 1, 2, 4, 8, etc...
        overZoom = pow(2, (z - zoomCap));
    }
	
    TileOverlay *tileOverlay = (TileOverlay *)self.overlay;
	
    // Get the list of tile images from the model object for this mapRect.  The
    // list may be 1 or more images (but not 0 because canDrawMapRect would have
    // returned NO in that case).
	
    NSArray *tilesInRect = [tileOverlay tilesInMapRect:mapRect zoomScale:zoomScale];
    CGContextSetAlpha(context, tileAlpha);
	
    for (ImageTile *tile in tilesInRect) {
        // For each image tile, draw it in its corresponding MKMapRect frame
        CGRect rect = [self rectForMapRect:tile.frame];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:tile.imagePath];
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
		
        // OverZoom mode - 1 when using tiles as is, 2, 4, 8 etc when overzoomed.
        CGContextScaleCTM(context, overZoom/zoomScale, overZoom/zoomScale);
        CGContextTranslateCTM(context, 0, image.size.height);
        CGContextScaleCTM(context, 1, -1);
        CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), [image CGImage]);
        CGContextRestoreGState(context);
		
        // Added release here because "Analyze" was reporting a potential leak. Bug in Apple's sample code?
        [image release];
    }
}

@end
