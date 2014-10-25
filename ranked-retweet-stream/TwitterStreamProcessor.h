//
//  TwitterStreamProcessor.h
//  ranked-retweet-stream
//

#import <Foundation/Foundation.h>

@interface TwitterStreamProcessor : NSObject <NSURLSessionDataDelegate>

@property (nonatomic) NSUInteger rollingWindowInterval;

+ (instancetype)sharedProcessor;
- (void)beginStreamProcessing;
- (void)endStreamProcessing;

@end
