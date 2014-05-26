//
//  ProgrameQiFanViewController.m
//  7fanGame
//
//  Created by liuym on 14-5-12.
//  Copyright (c) 2014年 liuym. All rights reserved.
//

#import "ProgrameQiFanViewController.h"
#import "ASIHttp/ASIFormDataRequest.h"
#import "ASIHttp/ASIHTTPRequest.h"
#import "SWHFViewController.h"
#import "MBProgressHUD.h"

#define QIFAN_LOCAL_NOTIFICATION 1
#define QIFAN_LOCAL_KEY @"QiFan"

@interface ProgrameQiFanViewController ()<ASIHTTPRequestDelegate, UITextFieldDelegate, MBProgressHUDDelegate>

@property (nonatomic, strong) IBOutlet UITextField *username;
@property (nonatomic, strong) IBOutlet UITextField *password;
@property (nonatomic, strong) IBOutlet UITextField *validata;
@property (nonatomic, strong) IBOutlet UIImageView *valiimg;
@property (nonatomic, strong) IBOutlet UIButton    *enterbutton;
@property (nonatomic, strong) IBOutlet UISwitch    *switchBtn;

@property (nonatomic, strong) NSString *VIEWSTATE;


@property (nonatomic, strong) NSURL *loginURL;
@property (nonatomic, strong) NSURL *validateCodeURL;

//add toast
@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation ProgrameQiFanViewController

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
	
	_loginURL = [NSURL URLWithString:@"http://passport.7fgame.com/7f/login.aspx"];
	
	_validateCodeURL = [NSURL URLWithString:@"http://passport.7fgame.com/7f/ValidateCode.aspx"];
	
	[self addImageViewTouch];
	[self setUpForDismissKeyboard];
	
	if([[self read:@"isLocalNtf"] isEqualToString:@"YES"]){
		[_switchBtn setOn:YES];
	}else{
		[_switchBtn setOn:NO];
	}
	
	_username.text = [self read:@"username"];
	_password.text = [self read:@"password"];
	
	//[[NSURLCache sharedURLCache] removeAllCachedResponses];
	//[self valiImage];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[_validata setText:@""];
	[self valiImage];
	[self becomeTextField];
}

- (void)becomeTextField
{
	if(_username.text.length == 0){
		[_username becomeFirstResponder];
	}else if(_password.text.length == 0){
		[_password becomeFirstResponder];
	}else if(_validata.text.length == 0){
		[_validata becomeFirstResponder];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login:(UIButton *)sender
{
	[_username resignFirstResponder];
	[_password resignFirstResponder];
	[_validata resignFirstResponder];
	NSString *alertMsg = nil;
	if(_username.text == nil || [_username.text isEqualToString:@""]){
		alertMsg = @"请输入用户名";
	}else if(_password.text == nil || [_password.text isEqualToString:@""]){
		alertMsg = @"请输入密码";
	}else if(_validata.text == nil || [_validata.text isEqualToString:@""]){
		alertMsg = @"请输入验证码";
	}else{		
		[self write:_username.text key:@"username"];
		[self write:_password.text key:@"password"];
		NSString *postString = [NSString stringWithFormat:@"__VIEWSTATE=%@&UserNameTxt=%@&UserPasswordTxt=%@&ValidateTxt=%@", @"/wEPDwUKMTMxNTUyMzI2MmQYAQUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgEFE0xvZ2luTGVmdDEkYnRuTG9naW6y5STJi8j60iU7VyArK7FvNSL9IQ==", _username.text, _password.text, _validata.text];
		//[self syncPost];
		//[ASIHTTPRequest setSessionCookies:nil];
		[self asyncPost:_loginURL postString:postString];
		
		_HUD = [[MBProgressHUD alloc] initWithView:self.view];
		[self.view addSubview:_HUD];
		_HUD.labelText = @"正在登入...";
		[_HUD show:YES];
		return;
	}
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:alertMsg delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
	[alert show];
	[self becomeTextField];
}

- (void)asyncPost:(NSURL *)url postString:(NSString *)postString
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	if(postString){
		NSLog(@"post:%@",postString);
		//将NSSrring格式的参数转换格式为NSData，POST提交必须用NSData数据。
		NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
		[request appendPostData:postData];
	}
	
	[request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];
	[request setRequestMethod:@"POST"];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)asyncGet:(NSURL *)url
{
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setRequestMethod:@"GET"];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	NSLog(@"request url = %@,data = s%@", request.url, request.responseString);
	NSRange range = [request.responseString rangeOfString:_username.text];
	if(range.location != NSNotFound){
		[_HUD removeFromSuperview];
		_HUD = nil;
		[self performSegueWithIdentifier:@"login_success" sender:self];
	}else{
		NSString *error = [self getSubStr:request.responseString startStr:@"alert('" endStr:@"')"];
		if(!error || error.length == 0){
			error = @"未知错误";
		}
		_HUD.mode = MBProgressHUDModeText;
		_HUD.labelText = error;
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(showFinish) userInfo:nil repeats:NO];
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	[self valiImage];
	NSError *error = [request error ];
	_HUD.mode = MBProgressHUDModeText;
	_HUD.labelText = [NSString stringWithFormat:@"请求错误:%@", error.userInfo];
	[_HUD showAnimated:YES whileExecutingBlock:^{
		//对话框显示时需要执行的操作
		sleep(2);
	} completionBlock:^{
		//操作执行完后取消对话框
		[_HUD removeFromSuperview];
		_HUD = nil;
	}];
	NSLog ( @"%@" ,error. userInfo );
}

- (void)showFinish
{
	[_validata becomeFirstResponder];
	[self valiImage];
	
	[_HUD removeFromSuperview];
	_HUD = nil;
}

- (void)loginOut
{
	NSURL *url = [NSURL URLWithString:@"http://passport.7fgame.com//Logout.aspx"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];
	[request setRequestMethod:@"GET"];
	[request setDelegate:self];
    [request startAsynchronous];
}

- (void)syncPost
{
	//post提交的参数，格式如下：
    //参数1名字=参数1数据&参数2名字＝参数2数据&参数3名字＝参数3数据&...
    NSString *post = [NSString stringWithFormat:@"__VIEWSTATE=%@&UserNameTxt=%@&UserPasswordTxt=%@&ValidateTxt=%@", @"/wEPDwUKMTMxNTUyMzI2MmQYAQUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgEFE0xvZ2luTGVmdDEkYnRuTG9naW6y5STJi8j60iU7VyArK7FvNSL9IQ==", _username.text, _password.text, _validata.text];
	
    //NSLog(@"post:%@",post);
	
    //将NSSrring格式的参数转换格式为NSData，POST提交必须用NSData数据。
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    //计算POST提交数据的长度
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    //NSLog(@"postLength=%@",postLength);
    //定义NSMutableURLRequest
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    //设置提交目的url
    [request setURL:[NSURL URLWithString:@"http://passport.7fgame.com/7f/login.aspx"]];
    //设置提交方式为 POST
	//[request setCachePolicy:NSURLCacheStorageNotAllowed];
    [request setHTTPMethod:@"POST"];
    //设置http-header:Content-Type
    //这里设置为 application/x-www-form-urlencoded ，如果设置为其它的，比如text/html;charset=utf-8，或者 text/html 等，都会出错。不知道什么原因。
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    //设置http-header:Content-Length
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //设置需要post提交的内容
    [request setHTTPBody:postData];
	
    //定义
    NSHTTPURLResponse* urlResponse = nil;
    NSError *error = [[NSError alloc] init];
    //同步提交:POST提交并等待返回值（同步），返回值是NSData类型。
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    //将NSData类型的返回值转换成NSString类型
    NSString *result = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSLog(@"user login check result:%@",result);
	[self valiImage];
}

- (void)addImageViewTouch
{
	_valiimg.userInteractionEnabled = YES;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTouch)];
    [_valiimg addGestureRecognizer:singleTap];
}

- (void)imageTouch
{
	[self valiImage];
	[self becomeTextField];
}

- (void)valiImage
{
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:_validateCodeURL]];
    _valiimg.image = image;
}

- (NSString *)getSubStr:(NSString *)allString startStr:(NSString *)startStr endStr:(NSString *)endStr;
{
	NSString *retStr = @"";
	if(allString && startStr && endStr){
		NSString *tmp = nil;
		NSRange startRange = [allString rangeOfString:startStr];
		if(startRange.location != NSNotFound){
			tmp = [allString substringFromIndex:startRange.location + startStr.length];
			if(tmp.length){
				NSRange endRange = [tmp rangeOfString:endStr];
				if(endRange.location != NSNotFound){
					tmp = [tmp substringToIndex:endRange.location];
					if(tmp && tmp.length){
						retStr = tmp;
					}
				}
			}
		}
	}
	return retStr;
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


#pragma -mark uitextfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

#pragma -mark add localnotifacation

- (BOOL)isHasNotification:(NSString *)key tag:(int)tag isCancel:(BOOL) isCancel
{
	// 这里我们要根据我们添加时设置的key和自定义的ID来删
	NSArray *narry=[[UIApplication sharedApplication] scheduledLocalNotifications];
	NSUInteger acount=[narry count];
	if (acount>0){
		// 遍历找到对应nfkey和notificationtag的通知
		for (int i=0; i<acount; i++){
			UILocalNotification *myUILocalNotification = [narry objectAtIndex:i];
			NSDictionary *userInfo = myUILocalNotification.userInfo;
			NSNumber *obj = [userInfo objectForKey:key];
			int mytag=[obj intValue];
			if (mytag==tag){
				if(isCancel){
					// 删除本地通知
					//[[UIApplication sharedApplication] cancelLocalNotification:myUILocalNotification];
					[[UIApplication sharedApplication] cancelAllLocalNotifications];
				}
				return YES;
			}
		}
	}
	return NO;
}

-(IBAction)switchAction:(UISwitch *)switchButton
{
    BOOL isButtonOn = [switchButton isOn];
    if (isButtonOn) {
		[self write:@"YES" key:@"isLocalNtf"];
        [self addLocalNotification:QIFAN_LOCAL_KEY tag:QIFAN_LOCAL_NOTIFICATION date:[self getDate:1 hour:9 min:57 sec:0]];
		[self addLocalNotification:QIFAN_LOCAL_KEY tag:QIFAN_LOCAL_NOTIFICATION date:[self getDate:7 hour:9 min:57 sec:0]];
		[self addLocalNotification:QIFAN_LOCAL_KEY tag:QIFAN_LOCAL_NOTIFICATION date:[self getDate:2 hour:18 min:57 sec:0]];
		[self addLocalNotification:QIFAN_LOCAL_KEY tag:QIFAN_LOCAL_NOTIFICATION date:[self getDate:3 hour:18 min:57 sec:0]];
		[self addLocalNotification:QIFAN_LOCAL_KEY tag:QIFAN_LOCAL_NOTIFICATION date:[self getDate:4 hour:18 min:57 sec:0]];
		[self addLocalNotification:QIFAN_LOCAL_KEY tag:QIFAN_LOCAL_NOTIFICATION date:[self getDate:5 hour:18 min:57 sec:0]];
		[self addLocalNotification:QIFAN_LOCAL_KEY tag:QIFAN_LOCAL_NOTIFICATION date:[self getDate:6 hour:18 min:57 sec:0]];
		
    }else {
        [self cancelNotification:QIFAN_LOCAL_KEY tag:QIFAN_LOCAL_NOTIFICATION];
    }
}
- (void)addLocalNotification:(NSString *)key tag:(int)tag date:(NSDate *)date
{
	// 添加本地通知
	UILocalNotification *notification=[[UILocalNotification alloc] init];
	if (notification!=nil){
		//NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		//[formatter setDateFormat:@"HH:mm:ss"];
		//触发通知的时间
		//NSDate *now = [formatter dateFromString:@"18:57:00"];
		notification.fireDate= date;
		// 设置时区，使用本地时区
		notification.timeZone=[NSTimeZone defaultTimeZone];
		notification.repeatInterval = NSWeekCalendarUnit;
		// 设置提示的文字
		notification.alertBody=@"换虎符时间还有3分钟开始,请注意时间！";
		// 设置提示音，使用默认的
		notification.soundName= UILocalNotificationDefaultSoundName;
		// 锁屏后提示文字，一般来说，都会设置与alertBody一样
		notification.alertAction=NSLocalizedString(@"换虎符时间还有3分钟开始,请注意时间！", nil);
		// 这个通知到时间时，你的应用程序右上角显示的数字. 获取当前的数字+1
		notification.applicationIconBadgeNumber = [[[UIApplication sharedApplication] scheduledLocalNotifications] count]+1;
		//给这个通知增加key 便于半路取消。nfkey这个key是自己随便写的，还有notificationtag也是自己定义的ID。假如你的通知不会在还没到时间的时候手动取消，那下面的两行代码你可以不用写了。取消通知的时候判断key和ID相同的就是同一个通知了。
		//NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tag],QIFAN_LOCAL_KEY,nil];
		//[notification setUserInfo:dict];
		// 启用这个通知
		[[UIApplication sharedApplication]   scheduleLocalNotification:notification];
	}
}

- (void)cancelNotification:(NSString *)key tag:(int)tag
{
	[self write:@"NO" key:@"isLocalNtf"];
	[[UIApplication sharedApplication] cancelAllLocalNotifications];
	[self isHasNotification:key tag:tag isCancel:YES];
}

- (void)write:(NSString *)write key:(NSString *)key
{
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
	[defaults setObject:write forKey:key];
	[defaults synchronize];
}

- (NSString *)read:(NSString *)key
{
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
	NSString *retStr = [defaults stringForKey:key];//根据键值取出name
	if(!retStr){
		return @"";
	}
	return retStr;
}

- (NSDate *)getDate:(int) weekIndex hour:(int)hour min:(int)min sec:(int)sec{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDate *now = [NSDate date];
	NSDateComponents *componentsForFireDate = [calendar components:(NSYearCalendarUnit |   NSHourCalendarUnit | NSMinuteCalendarUnit| NSSecondCalendarUnit | NSWeekOfYearCalendarUnit) fromDate: now];
	[componentsForFireDate setWeekday:weekIndex];
	[componentsForFireDate setHour:hour];
	[componentsForFireDate setMinute:min];
	[componentsForFireDate setSecond:sec];
	//NSLog(@"componentsForFireDate = %@", componentsForFireDate);
	NSDate *fireDateOfNotification = [calendar dateFromComponents: componentsForFireDate];
	//NSLog(@"date = %@", fireDateOfNotification);
	return fireDateOfNotification;
}

@end
