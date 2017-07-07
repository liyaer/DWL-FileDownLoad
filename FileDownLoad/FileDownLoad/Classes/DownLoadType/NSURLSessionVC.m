//
//  NSURLSessionVC.m
//  FileDownLoad
//
//  Created by pro on 17/6/2.
//  Copyright © 2017年 pro. All rights reserved.
//

#import "NSURLSessionVC.h"

/*
 *  类的扩展
 */

@interface NSURLSessionVC ()

@property (nonatomic,strong) UILabel *mesLab;

@end

/*
 *  类的实现
 */

@implementation NSURLSessionVC

-(UILabel *)mesLab
{
    if (!_mesLab)
    {
        _mesLab = [[UILabel alloc] initWithFrame:CGRectMake(100, 200, 150, 50)];
        _mesLab.font = [UIFont boldSystemFontOfSize:20.0];
        _mesLab.text = @"👌😂👌";
    }
    return _mesLab;
}




- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.mesLab];
    
    
    //构造URL
    NSString *fileURLStr = DownLoadURL;
    NSURL *fileURL = [NSURL URLWithString:fileURLStr];
    
    //创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL];
    
    //创建会话（这里使用了一个全局会话）
    NSURLSession *session = [NSURLSession sharedSession];
    
    //创建下载任务，并且启动它；（在非主线程中执行）
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
        __block void (^updateUI)(); //声明用于主线程更新 UI 的代码块
        
        if (!error) {
            NSLog(@"下载后的临时保存路径：%@", location);
            
            NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            savePath = [savePath stringByAppendingPathComponent:@"NSURLSession-Font"];
            NSURL *saveURL = [NSURL fileURLWithPath:savePath];
            NSError *saveError;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            //判断是否存在旧的目标文件，如果存在就先移除；避免无法复制问题
            if ([fileManager fileExistsAtPath:savePath]) {
                [fileManager removeItemAtPath:savePath error:&saveError];
                if (saveError) {
                    NSLog(@"移除旧的目标文件失败，错误信息：%@", saveError.localizedDescription);
                    
                    updateUI = ^ {
                            self.mesLab.text = @"下载失败";
                    };
                }
            }
            //不存在旧文件或者移除旧文件成功
            if (!saveError) {
                //把源文件复制到目标文件，当目标文件存在时，会抛出一个错误到 error 参数指向的对象实例
                //方法一（path 不能有 file:// 前缀）
                //                [fileManager copyItemAtPath:[location path]
                //                                     toPath:savePath
                //                                      error:&saveError];
                
                //方法二
                [fileManager copyItemAtURL:location
                                     toURL:saveURL
                                     error:&saveError];
                
                if (!saveError) {
                    NSLog(@"文件移动成功");
                    
                    updateUI = ^ {
                            self.mesLab.text = @"下载完成";
                    };
                } else {
                    NSLog(@"保存失败，错误信息：%@", saveError.localizedDescription);
                    
                    updateUI = ^ {
                            self.mesLab.text = @"下载失败";
                    };
                }
            }
            
        } else {
            NSLog(@"下载失败，错误信息：%@", error.localizedDescription);
            
            updateUI = ^ {
                      self.mesLab.text = @"下载失败";
            };
        }
        
        dispatch_async(dispatch_get_main_queue(), updateUI); //使用主队列异步方式（主线程）执行更新 UI 的代码块
    }];
    [downloadTask resume]; //恢复线程，启动任务
}



@end
