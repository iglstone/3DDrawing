//
//  CarvingRobot.m
//  Smooth Line View
//
//  Created by 郭龙 on 16/5/26.
//  Copyright © 2016年 culturezoo. All rights reserved.
//

#import "CarvingRobot.h"
#import <QuartzCore/QuartzCore.h>

#define DEFAULT_COLOR               [UIColor blackColor]
#define DEFAULT_WIDTH               5.0f
#define DEFAULT_BACKGROUND_COLOR    [UIColor whiteColor]

static const CGFloat kPointMinDistance = 4.0f;
static const CGFloat kPointMinDistanceSquared = kPointMinDistance * kPointMinDistance;

@interface CarvingRobot () {
    BOOL isTouching;
}
@property (nonatomic,assign) CGPoint currentPoint;
@property (nonatomic,assign) CGPoint previousPoint;
@property (nonatomic,assign) CGPoint previousPreviousPoint;

#pragma mark Private Helper function
CGPoint midPoint(CGPoint p1, CGPoint p2);
@end

@implementation CarvingRobot {
@private
    CGMutablePathRef _path;
}
@synthesize m_mutArray;

#pragma mark UIView lifecycle methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        // NOTE: do not change the backgroundColor here, so it can be set in IB.
        _path = CGPathCreateMutable();
        _lineWidth = DEFAULT_WIDTH;
        _lineColor = DEFAULT_COLOR;
        _empty = YES;
        m_mutArray = [NSMutableArray new];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = DEFAULT_BACKGROUND_COLOR;
        _path = CGPathCreateMutable();
        _lineWidth = DEFAULT_WIDTH;
        _lineColor = DEFAULT_COLOR;
        _empty = YES;
        m_mutArray = [NSMutableArray new];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 100, 40)];
        btn.backgroundColor = [UIColor orangeColor];
        [self addSubview:btn];
        [btn addTarget:self action:@selector(doneDraw) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitle:@"生成G代码" forState:UIControlStateNormal];
        
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    // clear rect
    [self.backgroundColor set];
    UIRectFill(rect);
    
    // get the graphics context and draw the path
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context, _path);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, self.lineWidth);
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    
    CGContextStrokePath(context);
    
    self.empty = NO;
}

-(void)dealloc {
    CGPathRelease(_path);
}

#pragma mark private Helper function

CGPoint midPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

#pragma mark Touch event handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    // initializes our point records to current location
    self.previousPoint = [touch previousLocationInView:self];
    self.previousPreviousPoint = [touch previousLocationInView:self];
    self.currentPoint = [touch locationInView:self];
    
    NSString *tm = [NSString stringWithFormat:@"G0 X%.2f Y%.2f",self.currentPoint.x, self.currentPoint.y];//定位
    [m_mutArray addObject:tm];
    // call touchesMoved:withEvent:, to possibly draw on zero movement
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];

    // if the finger has moved less than the min dist ...
    CGFloat dx = point.x - self.currentPoint.x;
    CGFloat dy = point.y - self.currentPoint.y;
    
    if ((dx * dx + dy * dy) < kPointMinDistanceSquared) {
        // ... then ignore this movement
        return;
    }
    if (isTouching == NO ) {
        isTouching = YES;
        [m_mutArray addObject:@"M03"];//开火
    }
    
    NSLog(@"%f, %f",point.x,point.y);
    NSString *tmpString = [NSString stringWithFormat:@"G1 X%.2f Y%.2f\n",point.x,point.y];
    [m_mutArray addObject:tmpString];
    
    // update points: previousPrevious -> mid1 -> previous -> mid2 -> current
    self.previousPreviousPoint = self.previousPoint;
    self.previousPoint = [touch previousLocationInView:self];
    self.currentPoint = [touch locationInView:self];
    
    CGPoint mid1 = midPoint(self.previousPoint, self.previousPreviousPoint);
    CGPoint mid2 = midPoint(self.currentPoint, self.previousPoint);
    
    // to represent the finger movement, create a new path segment,
    // a quadratic bezier path from mid1 to mid2, using previous as a control point
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL,
                              self.previousPoint.x, self.previousPoint.y,
                              mid2.x, mid2.y);
    
    // compute the rect containing the new segment plus padding for drawn line
    CGRect bounds = CGPathGetBoundingBox(subpath);
    CGRect drawBox = CGRectInset(bounds, -2.0 * self.lineWidth, -2.0 * self.lineWidth);
    
    // append the quad curve to the accumulated path so far.
    CGPathAddPath(_path, NULL, subpath);
    CGPathRelease(subpath);
    
    [self setNeedsDisplayInRect:drawBox];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    //    NSString *homepath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    //    NSString *homepath = NSHomeDirectory();
    //    NSString *path = [homepath stringByAppendingPathComponent:@"/record.txt"];
    //    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    //        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    //    }
    //    NSLog(@"%@",path);
    //    NSArray *array = @[@"yes",@"no"];
    
    isTouching = NO;
    [m_mutArray addObject:@"M05"];//熄火
}

- (void)doneDraw {
    NSString *final = @"G92 X0 Y0 Z0\nG21\nG90\nG1 F200.000000\nM05\n";
    for (NSString *st in m_mutArray) {
        final = [final stringByAppendingString:st];
    }
    final = [final stringByAppendingString:@"G0 X0.00 Y0.00\n"];
    BOOL re = [final writeToFile:[self documentsPath:@"guolong.gcode"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    if (re) {
        NSLog(@"write done");
    }else
        NSLog(@"write error");
    m_mutArray = nil;
}

-(NSString *)documentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}


- (void)writeDateToFile:(id )sender
{
    //    //5、创建数据缓冲区
    //    NSMutableData  *writer = [[NSMutableData alloc] init];
    //    //6、将字符串添加到缓冲中
    //    [writer appendData:[sender dataUsingEncoding:NSUTF8StringEncoding]];
    //    //7、将其他数据添加到缓冲中
    //    //将缓冲的数据写入到文件中
    //    [writer writeToFile:sender atomically:YES];
    
    //先写入文件
    NSString* _username = @"guolong";
    NSString* _phone = @"18050057025" ;
    NSString* _email = @"690193240@qq.com" ;
    NSString* _title = @"readText" ;
    NSString* filename = @"glData.txt";
    NSString* data = [NSString stringWithFormat:@"用户名：%@\n电话：%@\nEmail：%@\n地址：%@\n*****\n",_username,_phone,_email,_title,nil];
    [self writeFile:filename data:data];
    
}


-(void)writeFile:(NSString*)filename data:(NSString*)data
{
    //获得应用程序沙盒的Documents目录，官方推荐数据文件保存在此
    NSArray *path2 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_path = [path2 objectAtIndex:0];
    //NSLog(@"Documents Directory:%@",doc_path);
    
    //创建文件管理器对象
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString* _filename = [doc_path stringByAppendingPathComponent:filename];
    //NSString* new_folder = [doc_path stringByAppendingPathComponent:@"test"];
    //创建目录
    //[fm createDirectoryAtPath:new_folder withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createFileAtPath:_filename contents:[data dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
}

#pragma mark interface

-(void)clear {
    CGMutablePathRef oldPath = _path;
    CFRelease(oldPath);
    _path = CGPathCreateMutable();
    [self setNeedsDisplay];
}

@end


