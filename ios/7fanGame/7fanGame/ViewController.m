//
//  ViewController.m
//  7fanGame
//
//  Created by liuym on 14-5-12.
//  Copyright (c) 2014年 liuym. All rights reserved.
//

#import "ViewController.h"
#import "URLProtocol.h"

@interface ViewController ()<UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSString *webStr;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	_webStr = @"";
	
	/*if([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0){
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        CGRect rect = self.view.frame;
        rect.origin.y += 20;
        rect.size.height -= 20;
        self.view.frame = rect;
        self.view.backgroundColor = [UIColor blackColor];
    }*/
	//设置WebView禁止滚动
	//[(UIScrollView *)[[_webView subviews] objectAtIndex:0]    setBounces:NO];
	
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://passport.7fgame.com/7f/login.aspx"]];
	_webView.delegate = self;
	//[NSURLProtocol registerClass:[URLProtocol class]];
	[_webView loadRequest:request];
	
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	NSLog(@"webView = %@", webView.request.URL);
	NSString *urlStr = [NSString stringWithFormat:@"%@", webView.request.URL];
	NSString *meta = @"";
	_webStr = @"";
	if([urlStr isEqualToString:@"http://act.7fgame.com/SWHF2013/Home"]){
		meta = [NSString stringWithFormat:@"document.getElementsByTagName(\"input\")[0].value=\"%@\";", @"50"];
		[self appendString:meta];
	}else{
		meta = [NSString stringWithFormat:@"document.getElementsByName(\"UserNameTxt\")[0].value=\"%@\";", @"qq284278720"];
		[self appendString:meta];
		
		meta = [NSString stringWithFormat:@"document.getElementsByName(\"UserPasswordTxt\")[0].value=\"%@\";", @"13979185509"];
		[self appendString:meta];
		
		meta = [NSString stringWithFormat:@"document.getElementsByTagName(\"iframe\")[0].style.display=\"%@\";", @"none"];
		[self appendString:meta];
		
		meta = [NSString stringWithFormat:@"document.getElementsByTagName(\"table\")[6].style.display=\"%@\";", @"none"];
		[self appendString:meta];
		
			meta = [NSString stringWithFormat:@"document.getElementsByTagName(\"div\")[9].style.display=\"%@\";", @"none"];
		 [self appendString:meta];
		 
		 meta = [NSString stringWithFormat:@"document.getElementById(\"head\").style.display=\"%@\";", @"none"];
		 [self appendString:meta];
		 
	}
	[self webViewString:webView string:_webStr];
}

- (void) webViewDidStartLoad:(UIWebView*)theWebView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void) webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:error.localizedDescription delegate:self cancelButtonTitle:@"退出" otherButtonTitles:nil, nil];
    [alert show];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSLog(@"request URL = %@", request.URL);
	return YES;
}

- (void)webViewString:(UIWebView *)webView string:(NSString *)string
{
	[webView stringByEvaluatingJavaScriptFromString:string];
}

- (void)appendString:(NSString *)string
{
	if(string){
		_webStr = [NSString stringWithFormat:@"%@%@",_webStr, string];
	}
}

- (IBAction)webViewButton:(UIButton *)button
{
	if(button.tag == 101){
		if (_webView.canGoBack){
			[_webView goBack];
		}
	}else if(button.tag == 102){
		if (_webView.canGoForward){
			[_webView goForward];
		}
	}else if(button.tag == 103){
		[_webView reload];
	}else if(button.tag == 104){
		
	}
}

@end
