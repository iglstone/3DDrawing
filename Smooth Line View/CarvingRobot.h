//
//  CarvingRobot.h
//  Smooth Line View
//
//  Created by 郭龙 on 16/5/26.
//  Copyright © 2016年 culturezoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CarvingRobot : UIView

@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) BOOL empty;

@property (nonatomic) NSMutableArray *m_mutArray;

-(void)clear;

@end
