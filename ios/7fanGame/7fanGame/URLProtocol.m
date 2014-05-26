//
//  URLProtocol.m
//  7fanGame
//
//  Created by liuym on 14-5-12.
//  Copyright (c) 2014年 liuym. All rights reserved.
//

#import "URLProtocol.h"

@interface URLProtocol()

@property (nonatomic, strong) NSURLRequest *request;

@end

@implementation URLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)theRequest
{
	NSLog(@"URL = %@", theRequest.URL);
    if ([theRequest.URL.scheme caseInsensitiveCompare:@"myapp"] == NSOrderedSame) {
        return YES;
    }
    return NO;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)theRequest
{
	NSLog(@"url = %@", theRequest.URL);
    return theRequest;
}

- (void)startLoading
{
    NSLog(@"%@", _request.URL);
   /* NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[_request URL]
                                                        MIMEType:@"image/png"
                                           expectedContentLength:-1
                                                textEncodingName:nil];
	
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"image1" ofType:@"png"];
    NSData *data = [NSData dataWithContentsOfFile:imagePath];
	
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];*/
}

- (void)stopLoading
{
    NSLog(@"something went wrong!");
}

@end
