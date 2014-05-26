//
//  SWHFViewController.m
//  7fanGame
//
//  Created by liuym on 14-5-12.
//  Copyright (c) 2014年 liuym. All rights reserved.
//

#import "SWHFViewController.h"
#import "ASIHttp/ASIHTTPRequest.h"

@interface SWHFViewController ()<ASIHTTPRequestDelegate>{
	int logCount;
}

@property (atomic) BOOL isSuccess;
@property (nonatomic, strong) IBOutlet UILabel *swAll;
@property (nonatomic, strong) IBOutlet UILabel *levelOrder;
@property (nonatomic, strong) IBOutlet UILabel *levelRate;
@property (nonatomic, strong) IBOutlet UILabel *levelCount;
@property (nonatomic, strong) IBOutlet UITextField *swCount;
@property (nonatomic, strong) IBOutlet UILabel *useSwNum;
@property (nonatomic, strong) IBOutlet UITextView *logView;


@property (nonatomic, strong) NSURL *queryURL;
@property (nonatomic, strong) NSURL *homeInitURL;
@property (nonatomic, strong) NSURL *exchangedURL;
@property (nonatomic, strong) NSURL *loginOut;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSMutableArray *requestArray;

@end

@implementation SWHFViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setUpForDismissKeyboard];
	
	_queryURL = [NSURL URLWithString:@"http://app.7fgame.com/sso2/login?returnurl=http://act.7fgame.com/SWHF2013/Home"];
	
	_homeInitURL = [NSURL URLWithString:@"http://act.7fgame.com/SWHF2013/Home/HomePageInit"];
	
	_exchangedURL = [NSURL URLWithString:@"http://act.7fgame.com/SWHF2013/Home/HomeExchange"];

	_loginOut = [NSURL URLWithString:@"http://passport.7fgame.com//Logout.aspx"];
	
	[self asyncGet:_queryURL];
	
	_requestArray = [NSMutableArray array];

	//兑换成功
	_isSuccess = YES;
	logCount = 0;
	
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self stopTimer];
	[self clearRequestDelegate];
	//[ASIHTTPRequest clearSession];
	//[self asyncGet:_loginOut];
}

- (void)asyncPost:(NSURL *)url postString:(NSString *)postString
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[_requestArray addObject:request];
	if(postString){
		NSLog(@"post:%@",postString);
		//将NSSrring格式的参数转换格式为NSData，POST提交必须用NSData数据。
		NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
		[request appendPostData:postData];
	}
	
	[request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded;charset=UTF-8"];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];
	[request setRequestMethod:@"POST"];
	[request setTimeOutSeconds:3];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)exchangedPost
{
	int levelOrder = 1;
	if(levelOrder == 1){
		int amout = [[_swCount text] intValue];
		if(amout > 50){
			amout = 50;
		}
		NSString *postStrig = [NSString stringWithFormat:@"levelOrder=%d&amount=%d", levelOrder, amout];
		[self asyncPost:_exchangedURL postString:postStrig];
	}
}

- (void)asyncGet:(NSURL *)url
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[_requestArray addObject:request];
	[request setTimeOutSeconds:3];
	[request setRequestMethod:@"GET"];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (IBAction)buttonPress:(UIButton *)button
{
	if(button.tag == 101){
		[_logView setText:@""];
	}else if(button.tag == 102){
		[self asyncPost:_homeInitURL postString:nil];
	}else if(button.tag == 103){
		[self asyncGet:_queryURL];
	}else if(button.tag == 104){
		[self clearRequestDelegate];
	}
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	NSLog(@"request url = %@,data = s%@", request.url, request.responseString);
	NSString *urlStr = [NSString stringWithFormat:@"%@", request.url];
	if([urlStr isEqualToString:[NSString stringWithFormat:@"%@",@"http://act.7fgame.com/SWHF2013/Home"]]){
		[self asyncPost:_homeInitURL postString:nil];
	}else if([urlStr isEqualToString:[NSString stringWithFormat:@"%@",_homeInitURL]]){
		NSDictionary *dict = [self jsonStringToDictionary:request.responseString];
		if(dict != nil && [[dict objectForKey:@"Result"] intValue] == 0){
			NSDictionary *data = [self jsonStringToDictionary: [dict objectForKey:@"Data"]];
			if(data != nil && [data isKindOfClass:[NSDictionary class]]){
				NSString *str = [NSString stringWithFormat:@"%d", [[data objectForKey:@"Credit"] intValue]];
				_swAll.text = str;
				
				int isUseNum = [str intValue] / 5;
				if(isUseNum < 50){
					_swCount.text = [NSString stringWithFormat:@"%d", isUseNum];
				}
				
				NSDictionary *levelDict = [data objectForKey:@"Level"];
				
				//兑换声望等级
				int levelOrder = [[levelDict objectForKey:@"LevelOrder"] intValue];
				_levelOrder.text = [NSString stringWithFormat:@"LV%d", levelOrder];
				
				//兑换规则
				int levelRate = [[levelDict objectForKey:@"LevelRate"] intValue];
				_levelRate.text = [NSString stringWithFormat:@"%d声望/虎符", levelRate];
				
				//当前剩余等级数量
				int levelCount = [[levelDict objectForKey:@"LevelCount"] intValue];
				_levelCount.text = [NSString stringWithFormat:@"%d 个", levelCount];
				
				//兑换当前数量虎符消耗声望数
				int sw = [[_swCount text] intValue];
				_useSwNum.text = [NSString stringWithFormat:@"%d", sw * levelOrder * 5];

				[self appendLogText:[NSString stringWithFormat:@"兑换等级为: LV%d", levelOrder]];
				[self startTimer];

			}
		}else{
			[self appendLogText:@"请重新登入!"];
			[self stopTimer];
			//[self.navigationController popToRootViewControllerAnimated:NO];
		}
	}else if([urlStr isEqualToString:[NSString stringWithFormat:@"%@",_exchangedURL]]){
		NSDictionary *dict = [self jsonStringToDictionary:request.responseString];
		if(dict != nil && [[dict objectForKey:@"Result"] intValue] == 0){
			NSDictionary *data = [self jsonStringToDictionary: [dict objectForKey:@"Data"]];
			if(data != nil && [data isKindOfClass:[NSDictionary class]]){
				int ret = [[data objectForKey:@"Result"] intValue];
				NSString *msg = [data objectForKey:@"Message"];
				_isSuccess = YES;
				[self appendLogText:[NSString stringWithFormat:@"%@", msg]];
				if(ret == 0){
					[self stopTimer];
				}
			}
		}else{
			NSLog(@"error msg = %@", [dict objectForKey:@"Message"]);
		}
	}
	
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error ];
	NSLog ( @"%@ -- url ＝ %@" ,error. userInfo, request.url);
	NSString *urlStr = [NSString stringWithFormat:@"%@", request.url];
	if([urlStr isEqualToString:[NSString stringWithFormat:@"%@",_queryURL]] || [urlStr isEqualToString:[NSString stringWithFormat:@"%@",@"http://act.7fgame.com/SWHF2013/Home"]]){
		[self appendLogText:@"页面 1超时,刷新中..."];
		[self asyncGet:_queryURL];
	}else if([urlStr isEqualToString:[NSString stringWithFormat:@"%@",_homeInitURL]]){
		[self appendLogText:@"页面 2超时,刷新中..."];
		[self asyncPost:_homeInitURL postString:nil];
	}
}

- (NSDictionary *)jsonStringToDictionary:(NSString *)jsonStrig
{
    if(jsonStrig){
        NSError *error = nil;
        NSData *jsonData = [jsonStrig dataUsingEncoding:NSUTF8StringEncoding];
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
        if(error || jsonObject == nil){
            return nil;
        }else if([jsonObject isKindOfClass:[NSDictionary class]]){
            return (NSDictionary*)jsonObject;
        }
    }
    return nil;
}

- (void)timerFired
{
	/*if(levelOrder != 1){
		[self asyncPost:_homeInitURL postString:nil];
	}else{
		[self exchangedPost];
	}*/
	if(!_isSuccess){
		[self appendLogText:@"兑换失败，超时!"];
	}
	_isSuccess = NO;
	[self clearRequestDelegate];
	[self exchangedPost];
}

- (void)startTimer
{
	if(!_timer.isValid){
		_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
	}
}

- (void)stopTimer
{
	if(_timer.isValid){
		[_timer invalidate];
	}
}

- (void)clearRequestDelegate
{
	for(id object in _requestArray){
		if([object isKindOfClass:[ASIHTTPRequest class]]){
			ASIHTTPRequest *request = (ASIHTTPRequest *)object;
			[request clearDelegatesAndCancel];
		}
	}
	[_requestArray removeAllObjects];
}

- (void)appendLogText:(NSString *)text {
	if(logCount == 10){
		logCount = 0;
		[_logView setText:@""];
	}
    NSMutableString *str =[[NSMutableString alloc] init];
    [str appendFormat:@"%@%@ -%d\r",_logView.text,text, ++logCount];
    
    _logView.text = str;
    [_logView scrollRectToVisible:CGRectMake(0, _logView.contentSize.height-15, _logView.contentSize.width, 10) animated:YES];
}

#pragma -mark dismiss keyboard
- (void)setUpForDismissKeyboard {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	UITapGestureRecognizer *singleTapGR =
	[[UITapGestureRecognizer alloc] initWithTarget:self
											action:@selector(tapAnywhereToDismissKeyboard:)];
	NSOperationQueue *mainQuene =[NSOperationQueue mainQueue];
	[nc addObserverForName:UIKeyboardWillShowNotification
					object:nil
					 queue:mainQuene
				usingBlock:^(NSNotification *note){
					[self.view addGestureRecognizer:singleTapGR];
				}];
	[nc addObserverForName:UIKeyboardWillHideNotification
					object:nil
					 queue:mainQuene
				usingBlock:^(NSNotification *note){
					[self.view removeGestureRecognizer:singleTapGR];
				}];
}

- (void)tapAnywhereToDismissKeyboard:(UIGestureRecognizer *)gestureRecognizer {
	//此method会将self.view里所有的subview的first responder都resign掉
	[self.view endEditing:YES];
}

@end
