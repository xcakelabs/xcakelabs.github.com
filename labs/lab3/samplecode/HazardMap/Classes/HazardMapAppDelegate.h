#import <UIKit/UIKit.h>

@class HazardMapViewController;

@interface HazardMapAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    HazardMapViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet HazardMapViewController *viewController;

@end

