//
//  ViewController.h
//  ranked-retweet-stream
//

#import <UIKit/UIKit.h>

@interface RankingWindowSelectionViewController : UIViewController

// Used to set window size in increments of whole minutes (sixty seconds)
@property (strong, nonatomic) IBOutlet UIStepper * windowSizeStepper;
@property (strong, nonatomic) IBOutlet UILabel * windowSizeLabel;
@property (strong, nonatomic) IBOutlet UILabel * selectionInstructions;

@end

