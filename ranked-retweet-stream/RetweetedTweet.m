//
//  RetweetedTweet.m
//  ranked-retweet-stream
//
//  Created by Tom Tsai on 10/24/14.
//  Copyright (c) 2014 Tom Tsai. All rights reserved.
//

#import "RetweetedTweet.h"

@implementation RetweetedTweet

- (id)initWithId:(NSString *) idString andText:(NSString *) text
{
    self = [super init];
    if (self) {
        _tweetId = idString;
        _tweetText = text;
        _retweetCount = 1;
    }
    return self;
}

- (void)incrementRetweetCount
{
    self.retweetCount += 1;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[RetweetedTweet class]])
    {
        RetweetedTweet * tweet = object;
        return [self isEqualToRetweetedTweet:tweet];
    }
    else
    {
        return NO;
    }
}

- (NSUInteger)hash
{
    return [self.tweetId hash];
}

- (BOOL)isEqualToRetweetedTweet:(RetweetedTweet *) aRetweetedTweet
{
    if ([self.tweetId isEqualToString:aRetweetedTweet.tweetId])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
