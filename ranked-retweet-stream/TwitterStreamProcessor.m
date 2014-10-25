//
//  TwitterStreamProcessor.m
//  ranked-retweet-stream
//

#import "TwitterStreamProcessor.h"
#import "FHSTwitterEngine.h"
#import "RetweetedTweet.h"

@interface TwitterStreamProcessor ()

@property (nonatomic) BOOL isStreaming;
@property (nonatomic) NSUInteger circularBufferIndexPosition;
@property (strong, nonatomic) NSMutableArray * circularWindowBuffer;
@property (strong, nonatomic) NSArray * topTenRetweetedTweets;
@property (strong, nonatomic) NSMutableSet * retweetedTweets;
@property (strong, nonatomic) NSMutableDictionary * tweetIdsToObjects;
@property (strong, nonatomic) NSTimer * windowTimer;
@property (strong, nonatomic) NSTimer * topTenGenerationTimer;

@end

@implementation TwitterStreamProcessor

+ (instancetype)sharedProcessor
{
    static TwitterStreamProcessor *_sharedProcessor = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedProcessor = [[self alloc] init];
    });
    
    return _sharedProcessor;
}

- (id)init
{
    self = [super init];
    if (self) {
        _rollingWindowInterval = 0;
        _circularBufferIndexPosition = 0;
        _windowTimer = nil;
        _retweetedTweets = [NSMutableSet set];
        _topTenRetweetedTweets = nil;
        _topTenGenerationTimer = nil;
        _tweetIdsToObjects = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Stream processing
- (void)beginStreamProcessing
{
    if (self.rollingWindowInterval > 0)
    {
        self.isStreaming = YES;
        self.windowTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(advanceRollingWindow) userInfo:nil repeats:YES];
        self.topTenGenerationTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(outputTopTen) userInfo:nil repeats:YES];
        
        [[FHSTwitterEngine sharedEngine]streamSampleStatusesWithBlock:^(id result, BOOL *stop) {
            if (![result isKindOfClass:[NSError class]])
            {
                if ([result objectForKey:@"retweeted_status"] != nil) {
                    id originalTweet = [result objectForKey:@"retweeted_status"];
                    RetweetedTweet * tweet = [[RetweetedTweet alloc] initWithId:[[originalTweet objectForKey:@"id_str"] copy]
                                                                        andText:[[originalTweet objectForKey:@"text"] copy]];
                    
                    // Test if the original tweet has already been seen. If it has, increment its retweet count.
                    // Otherwise, create a local representation of it with the retweet count initialized to 1.
                    RetweetedTweet * localRepresentation = [self.retweetedTweets member:tweet];
                    if (localRepresentation == nil)
                    {
                        [self.retweetedTweets addObject:tweet];
                        // Mapping used to easily look up tweets by their ids
                        [self.tweetIdsToObjects setObject:tweet forKey:tweet.tweetId];
                        localRepresentation = tweet;
                    }
                    else
                    {
                        [localRepresentation incrementRetweetCount];
                    }
                    
                    // Add the local representation to the appropriate dictionary representing the current time interval.
                    [self addTweetToRollingWindow:localRepresentation];
                    
                }
            }
            if (self.isStreaming == NO) {
                *stop = YES;
            }
        }];
    }
}

- (void)endStreamProcessing
{
    self.isStreaming = NO;
    [self.windowTimer invalidate];
    self.windowTimer = nil;
    [self.topTenGenerationTimer invalidate];
    self.topTenGenerationTimer = nil;
}

- (void)addTweetToRollingWindow:(RetweetedTweet *) retweetedTweet
{
    NSString * retweetedTweetId = retweetedTweet.tweetId;
    
    // Get the dictionary that represent tweets seen in the current interval.
    
    NSMutableDictionary * intervalDictionary = [self currentIntervalDictionary];
    
    if (retweetedTweetId != nil)
    {
        NSNumber * seenTweetCount = [intervalDictionary objectForKey:retweetedTweetId];
        
        // If the retweeted tweet has already been seen during this interval, increment its count.
        if (seenTweetCount != nil)
        {
            NSNumber * newSeenTweetCount = [NSNumber numberWithUnsignedInteger:([seenTweetCount unsignedIntegerValue] + 1)];
            [intervalDictionary setObject:newSeenTweetCount forKey:retweetedTweetId];
        }
        // Otherwise, add a new key-value pair to the interval's dictionary.
        else
        {
            [intervalDictionary setObject:[NSNumber numberWithUnsignedInteger:1] forKey:retweetedTweet.tweetId];
        }
    }
    
}

- (NSMutableDictionary *)currentIntervalDictionary
{
    // Create the circular buffer, if necessary.
    if (self.circularWindowBuffer == nil)
    {
        self.circularWindowBuffer = [NSMutableArray arrayWithCapacity:(60 * self.rollingWindowInterval)];
        // Add initial interval dictionary
        [self.circularWindowBuffer addObject:[NSMutableDictionary dictionary]];
    }
    
    NSMutableDictionary * currentIntervalDictionary;
    
    // If the circular buffer is not full, simply retrieve the most recently added interval dictionary.
    if (![self isCircularBufferFull])
    {
        currentIntervalDictionary = self.circularWindowBuffer.lastObject;
    }
    // Otherwise, retrieve the interval dictionary using the current position in the cyclic buffer.
    else
    {
        currentIntervalDictionary = self.circularWindowBuffer[self.circularBufferIndexPosition];
    }
    
    return currentIntervalDictionary;
}

- (void)decrementInvalidCounts:(NSMutableDictionary *) invalidatedCounts
{
    NSArray * tweetIds = [invalidatedCounts allKeys];
    
    for (NSString * tweetId in tweetIds)
    {
        RetweetedTweet * tweet = [self.tweetIdsToObjects objectForKey:tweetId];
        NSNumber * invalidatedCount = [invalidatedCounts objectForKey:tweetId];
        tweet.retweetCount -= [invalidatedCount intValue];
        if (tweet.retweetCount <= 0 && tweet != nil)
        {
            // Remove the tweet from the set of seen tweets as it has fallen out of the rolling window
            [self.retweetedTweets removeObject:tweet];
            [self.tweetIdsToObjects removeObjectForKey:tweetId];
        }
    }
}

- (void)advanceRollingWindow
{
    if ([self isCircularBufferFull])
    {
        // Invalidate count data from dictionary at the current position
        [self decrementInvalidCounts:[self currentIntervalDictionary]];
        
        // Replace the interval dictionary at the current position
        [self.circularWindowBuffer replaceObjectAtIndex:self.circularBufferIndexPosition withObject:[NSMutableDictionary dictionary]];
    }
    else
    {
        [self.circularWindowBuffer addObject:[NSMutableDictionary dictionary]];
    }

    // Advance current position or reset if necessary
    if (self.circularBufferIndexPosition == (60 * self.rollingWindowInterval) - 1)
    {
        self.circularBufferIndexPosition = 0;
    }
    else
    {
        self.circularBufferIndexPosition += 1;
    }
}

- (BOOL)isCircularBufferFull
{
    return !(self.circularWindowBuffer.count < (60 * self.rollingWindowInterval));
}

- (NSArray *)generateTopTen
{
    if (self.retweetedTweets.count != 0)
    {
        // Using tweetId in ascending order as a tie-breaker for sorting by count
        NSArray * sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"retweetCount" ascending:NO],
                                      [NSSortDescriptor sortDescriptorWithKey:@"tweetId" ascending:YES]];
        NSArray * sortedTweets = [self.retweetedTweets sortedArrayUsingDescriptors:sortDescriptors];
        NSRange topTen;
        topTen.location = 0;
        topTen.length = (self.retweetedTweets.count <= 10) ? self.retweetedTweets.count : 10;
        NSArray * topTenTweets = [sortedTweets subarrayWithRange:topTen];
        return topTenTweets;
    }
    else
    {
        return nil;
    }
}

- (void)outputTopTen
{
    // Generate top ten; Format it; Print log
    NSArray * currentTopTenTweets = [self generateTopTen];
    if (currentTopTenTweets != nil)
    {
        NSLog(@"Top Ten retweeted tweets:\n");
        for (int n = 0; n < currentTopTenTweets.count; n++)
        {
            RetweetedTweet * tweet = currentTopTenTweets[n];
            NSLog(@"%d: Count: %@\n Text: %@\n", (n+1), [[NSNumber numberWithInt:tweet.retweetCount] stringValue], tweet.tweetText);
        }
    }
}

@end
