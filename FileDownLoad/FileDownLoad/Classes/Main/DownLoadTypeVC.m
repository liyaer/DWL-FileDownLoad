//
//  DownLoadTypeVC.m
//  FileDownLoad
//
//  Created by pro on 17/6/2.
//  Copyright © 2017年 pro. All rights reserved.
//

#import "DownLoadTypeVC.h"

/*
 *  cell 重用标识符
 */

static NSString *systemCellIden = @"downLoadType";

/*
 *  类的扩展
 */

@interface DownLoadTypeVC ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) NSArray *downLoadTypes;

@property (nonatomic,strong) NSArray *VCs;

@end

/*
 *  类的实现
 */

@implementation DownLoadTypeVC

#pragma mark - 懒加载

-(UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

-(NSArray *)downLoadTypes
{
    if (!_downLoadTypes)
    {
        _downLoadTypes = @[@"NSURLConnection",@"NSURLConnectionDelegate",@"NSURLSession",@"NSURLSessionDelegate",@"AFNetWorking"];
    }
    return _downLoadTypes;
}

-(NSArray *)VCs
{
    if (!_VCs)
    {
        _VCs = @[@"NSURLConnectionVC",@"NSURLConnectionDelegateVC",@"NSURLSessionVC",@"NSURLSessionDelegateVC",@"AFNetWorkingVC"];
    }
    return _VCs;
}




#pragma mark - viewDidLoad 初始化

- (void)viewDidLoad {
    [super viewDidLoad];

    
    [self setUI];
    
    //测试沙盒中temp文件夹是否在一次运行结束时，自动清除temp文件夹下的内容（不会自动清除，需要手动删除）
    [self testTempWhenDelete];
}

-(void)setUI
{
    self.navigationController.navigationBar.translucent = NO;
    
    self.view.backgroundColor = [UIColor yellowColor];
    
    [self.view addSubview:self.tableView];
}

-(void)testTempWhenDelete
{
    NSString *temp = NSTemporaryDirectory();
    NSString *path = [temp stringByAppendingPathComponent:@"book"];
    NSFileManager *fileManger = [NSFileManager defaultManager];
    if (![fileManger fileExistsAtPath:path])
    {
        DLog(@"不存在测试文件夹，我就建！");
        [fileManger createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
//===================================沙盒=================================================
        //writeToFile到沙盒
        NSString *txtPath = [path stringByAppendingPathComponent:@"nihao.txt"];
//        [fileManger createFileAtPath:txtPath contents:nil attributes:nil];创建文件写不写无所谓，writeToFile文件不存在的话会自动创建
        if ([self.VCs writeToFile:txtPath atomically:YES])
        {
            DLog(@"===writeToFile===写入成功！");
        }
        
        //writeToURL到沙盒
        NSString *URLPath = [path stringByAppendingPathComponent:@"URL.txt"];
        if ([self.VCs writeToURL:[NSURL fileURLWithPath:URLPath] atomically:YES])
//        if ([self.VCs writeToURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@",URLPath]] atomically:YES]) 这个也可以
        {
            DLog(@"===writeToURL===写入成功！");
        }
        
//====以下两段代码也会提示写入成功，但是检查文件发现内容并未被写入，原因在Bundle写的很清楚了====
//        //writeToFile到项目目录下
//        NSString *URLBundle = [[NSBundle mainBundle] pathForResource:@"Bundle" ofType:@"txt"];
//        if ([self.downLoadTypes writeToFile:URLBundle atomically:YES])
//        {
//            DLog(@"===writeToURL===写入成功！");
//        }
        
//        //writeToURL到项目目录下
//        NSString *URLBundle = [[NSBundle mainBundle] pathForResource:@"Bundle" ofType:@"txt"];
//        if ([self.downLoadTypes writeToURL:[NSURL fileURLWithPath:URLBundle] atomically:YES])
//        {
//            DLog(@"===writeToURL===写入成功！");
//        }
        
        NSString *URLBundle = [[NSBundle mainBundle] pathForResource:@"Bundle" ofType:@"txt"];
        NSString *string = [NSString stringWithContentsOfFile:URLBundle encoding:NSUTF8StringEncoding error:nil];
        DLog(@"%@",string);

        
        //通过界面效果，方便快捷的知道测试结果（再次运行APP，temp文件夹下内容是否自动清除）
        self.tableView.backgroundColor = [UIColor greenColor];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [fileManger removeItemAtPath:path error:nil];
        });
    }
}





#pragma mark - TabView Delegate and DataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.downLoadTypes.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:systemCellIden];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:systemCellIden];
    }
    cell.textLabel.text = self.downLoadTypes[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewController *vc = [[NSClassFromString(self.VCs[indexPath.row]) alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}



@end
