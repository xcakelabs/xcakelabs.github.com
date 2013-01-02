#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface HazardMapViewController : UIViewController <MKMapViewDelegate> {
    IBOutlet MKMapView *map;
}

@end

