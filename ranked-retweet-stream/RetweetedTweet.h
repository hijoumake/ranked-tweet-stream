//
//  RetweetedTweet.h
//  ranked-retweet-stream
//
//  Created by Tom Tsai on 10/24/14.
//  Copyright (c) 2014 Tom Tsai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RetweetedTweet : NSObject

@property (strong, nonatomic) NSString * tweetText;
@property (strong, nonatomic) NSString * tweetId;
@property (nonatomic) int retweetCount;

- (id)initWithId:(NSString *) idString andText:(NSString *) text;
- (void)incrementRetweetCount;
- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

@end
