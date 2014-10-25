//
//  ViewController.m
//  ranked-retweet-stream
//

#import "RankingWindowSelectionViewController.h"
#import "FHSTwitterEngine.h"
#import "TwitterStreamProcessor.h"
#import "Constants.h"

#define MAX_WINDOW_SIZE 20
#define MIN_WINDOW_SIZE 1


@interface RankingWindowSelectionViewController ()

@property (nonatomic) BOOL isStreaming;

@end

@implementation RankingWindowSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Start", @"Start") style:UIBarButtonItemStylePlain target:self action:@selector(startRanking)];
    self.navigationItem.title = NSLocalizedString(@"Ranked Retweets", @"Ranked Retweets");
    
    //Setup stepper values
    [self.windowSizeStepper addTarget:self action:@selector(updateWindowLabel) forControlEvents:UIControlEventTouchUpInside];
    self.windowSizeStepper.minimumValue = MIN_WINDOW_SIZE;
    self.windowSizeStepper.maximumValue = MAX_WINDOW_SIZE;
    self.windowSizeStepper.wraps = YES;
    
    [self provideConnectionCredentials];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button actions

- (void)startRanking
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopRanking)];
    self.windowSizeStepper.userInteractionEnabled = NO;
    self.isStreaming = YES;
    //Set up Twitter Stream Processor
    [[TwitterStreamProcessor sharedProcessor] setRollingWindowInterval:(NSUInteger)self.windowSizeStepper.value];
    [[TwitterStreamProcessor sharedProcessor] beginStreamProcessing];
}

- (void)stopRanking
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Start", @"Start") style:UIBarButtonItemStylePlain target:self action:@selector(startRanking)];
    self.windowSizeStepper.userInteractionEnabled = YES;
    self.isStreaming = NO;
}

- (void)updateWindowLabel
{
    if (self.windowSizeStepper.value == 1)
    {
        self.windowSizeLabel.text = [NSString stringWithFormat:@"%.f minute", self.windowSizeStepper.value];
    }
    else
    {
        self.windowSizeLabel.text = [NSString stringWithFormat:@"%.f minutes", self.windowSizeStepper.value];
    }
}

#pragma mark - Connection methods

- (void)provideConnectionCredentials
{
    [[FHSTwitterEngine sharedEngine] permanentlySetConsumerKey:TWITTER_CONSUMER_KEY andSecret:TWITTER_CONSUMER_SECRET];
    // Programmatically providing access token and secret
    FHSToken * token = [[FHSToken alloc] init];
    token.key = TWITTER_ACCESS_TOKEN_KEY;
    token.secret = TWITTER_ACCESS_TOKEN_SECRET;
    [[FHSTwitterEngine sharedEngine] setAccessToken:token];

}

@end
