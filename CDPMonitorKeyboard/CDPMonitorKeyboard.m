//
//  CDPMonitorKeyboard.m
//  keyboard
//
//  Created by 柴东鹏 on 15/4/26.
//  Copyright (c) 2015年 CDP. All rights reserved.
//

#import "CDPMonitorKeyboard.h"

#define CDPSWIDTH   [UIScreen mainScreen].bounds.size.width
#define CDPSHEIGHT  [UIScreen mainScreen].bounds.size.height
#define CDPMinX(view) CGRectGetMinX(view.frame)
#define CDPMinY(view) CGRectGetMinY(view.frame)
#define CDPMaxX(view) CGRectGetMaxX(view.frame)
#define CDPMaxY(view) CGRectGetMaxY(view.frame)
#define CDPGetWidth(view) view.bounds.size.width
#define CDPGetHeight(view) view.bounds.size.height

@implementation CDPMonitorKeyboard{
    
    UIView *_superView;//输入view的父view
    
    CDPMonitorKeyboardMode _mode;//当前模式
    
    NSInteger _valueOfHigher;//输入视图需要高出键盘的高度

    NSInteger _topHeight;//navigationBar高度+状态栏高度(20)
    
    NSInteger _keyboardHeight;//键盘高度
}

//单例化
+(CDPMonitorKeyboard *)defaultMonitorKeyboard{
    static CDPMonitorKeyboard *monitorKeyboard= nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken,^{
        monitorKeyboard=[[self alloc] init];

    });
    return monitorKeyboard;
}
-(instancetype)init{
    if (self=[super init]) {
        //增加监听，当键盘出现时收消息
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        //增加监听，当键盘退出时收消息
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        //增加监听，当textField开始编辑时收消息
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldBeginEdit:) name:UITextFieldTextDidBeginEditingNotification object:nil];
        //增加监听，当textView开始编辑时收消息
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewBeginEdit:) name:UITextViewTextDidBeginEditingNotification object:nil];
    }
    
    return self;
}
-(void)dealloc{
    //取消监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];

}
//自动监听调用方法(仅需调用一次，若果需要改变参数再调用)
-(void)sendValueWithSuperView:(UIView *)superView higherThanKeyboard:(NSInteger)valueOfHigher andMode:(CDPMonitorKeyboardMode)mode navigationControllerTopHeight:(NSInteger)topHeight{
    _superView=superView;
    _valueOfHigher=valueOfHigher;
    _mode=mode;
    _topHeight=topHeight;
}
#pragma mark - textField和textView开始编辑监听
//textField开始编辑监听
-(void)textFieldBeginEdit:(NSNotification *)notification{
    switch (_mode) {
        case CDPMonitorKeyboardDefaultMode:
            [self defaultModeWithKeyboardHeight:_keyboardHeight];
            break;
        case CDPMonitorKeyboardTableViewMode:
            [self tableViewModeWithKeyboardHeight:_keyboardHeight];
            break;
        case CDPMonitorKeyboardScrollViewMode:
            [self scrollViewModeWithKeyboardHeight:_keyboardHeight];
            break;
            
        default:
            NSLog(@"CDPMonitorKeyboardMode模式设定错误");
            break;
    }
}
//textView开始编辑监听
-(void)textViewBeginEdit:(NSNotification *)notification{
    switch (_mode) {
        case CDPMonitorKeyboardDefaultMode:
            [self defaultModeWithKeyboardHeight:_keyboardHeight];
            break;
        case CDPMonitorKeyboardTableViewMode:
            [self tableViewModeWithKeyboardHeight:_keyboardHeight];
            break;
        case CDPMonitorKeyboardScrollViewMode:
            [self scrollViewModeWithKeyboardHeight:_keyboardHeight];
            break;
            
        default:
            NSLog(@"CDPMonitorKeyboardMode模式设定错误");
            break;
    }
}
#pragma mark - 监听系统键盘
//键盘出现
-(void)keyboardWillShow:(NSNotification *)notification{
    [self didKeyboardWillShowWithNotification:notification];
    if (_delegate) {
        [_delegate didWhenKeyboardWillShow:notification];
    }
}
//键盘消失
-(void)keyboardWillHide:(NSNotification *)notification{
    [self didKeyboardWillHide];
    if (_delegate) {
        [_delegate didWhenKeyboardWillHide:notification];
    }
}
#pragma mark - 键盘出现和消失调用方法
//当键盘出现时调用方法
-(void)didKeyboardWillShowWithNotification:(NSNotification *)notification{
    //获取键盘的高度

    NSDictionary *userInfo=[notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    NSInteger height = keyboardRect.size.height;
    _keyboardHeight=height;
    
    switch (_mode) {
        case CDPMonitorKeyboardDefaultMode:
            [self defaultModeWithKeyboardHeight:height];
            break;
        case CDPMonitorKeyboardTableViewMode:
            [self tableViewModeWithKeyboardHeight:height];
            break;
        case CDPMonitorKeyboardScrollViewMode:
            [self scrollViewModeWithKeyboardHeight:height];
            break;
            
        default:
            NSLog(@"CDPMonitorKeyboardMode模式设定错误");
            break;
    }
    
}
//当键退出时调用
-(void)didKeyboardWillHide{
    [UIView animateWithDuration:0.3 animations:^{
        if (_superView) {
            _superView.transform=CGAffineTransformIdentity;
        }
    }];
}
#pragma mark - 键盘各模式
//一般模式下
-(void)defaultModeWithKeyboardHeight:(NSInteger)height{
    [UIView animateWithDuration:0.25 animations:^{
        _superView.transform=CGAffineTransformIdentity;
    }];
    
    for (UIView *view in _superView.subviews) {
        if (view.isFirstResponder==YES) {
            NSInteger value=CDPGetHeight(_superView)-_topHeight-CDPMaxY(view);
            if (value<height) {
                [UIView animateWithDuration:0.3 animations:^{
                    //防止超出屏幕最大范围
                    if ((height-value)+_valueOfHigher-height>0) {
                        _superView.transform=CGAffineTransformMakeTranslation(0,-height);
                    }
                    else{
                        _superView.transform=CGAffineTransformMakeTranslation(0,value-height-_valueOfHigher);
                    }
                }];
            }
        }
    }

}
//tableView模式下
-(void)tableViewModeWithKeyboardHeight:(NSInteger)height{
    [UIView animateWithDuration:0.25 animations:^{
        _superView.transform=CGAffineTransformIdentity;
    }];
    
    if (_mode==CDPMonitorKeyboardTableViewMode) {
        UITableView *tableView=(UITableView *)_superView;
        
        for (UIView *wrapperView in tableView.subviews) {
            if (CDPGetWidth(wrapperView)==CDPGetWidth(tableView)&&CDPGetHeight(wrapperView)==CDPGetHeight(tableView)) {
                for (UITableViewCell *cell in [wrapperView subviews]) {
                    for (UIView *view in [cell.contentView subviews]) {
                        if (view.isFirstResponder==YES) {
                            if (tableView.contentOffset.y>0) {
                                _isShowKeyboard=YES;
                                NSIndexPath *indexPath=[tableView indexPathForCell:cell];
                                [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                            }
                            _isShowKeyboard=NO;
                            
                            
                            UIView *cellView=view.superview.superview;
                            float value1=CDPMinY(cellView)+CDPMaxY(view)-tableView.contentOffset.y;
                            float value2=CDPGetHeight(tableView)-value1;
                            
                            if (value2<0) {
                                float y=tableView.contentOffset.y;
                                tableView.contentOffset=CGPointMake(0,y-value2);
                                value2=0;
                            }
                            float value=value2+(CDPSHEIGHT-CDPMaxY(tableView)-_topHeight);
                            [UIView animateWithDuration:0.3 animations:^{
                                _superView.transform=CGAffineTransformMakeTranslation(0,value-height-_valueOfHigher);
                            }];
                        }
                    }
                }
            }
        }
    }
}
//scrollView模式下
-(void)scrollViewModeWithKeyboardHeight:(NSInteger)height{
    [UIView animateWithDuration:0.25 animations:^{
        _superView.transform=CGAffineTransformIdentity;
    }];
    
    if (_mode==CDPMonitorKeyboardScrollViewMode) {
        UIScrollView *scrollView=(UIScrollView *)_superView;
        for (UIView *view in [_superView subviews]) {
            if (view.isFirstResponder==YES) {
                float value1=CDPMaxY(view)-scrollView.contentOffset.y;
                float value2=CDPGetHeight(scrollView)-value1;
                if (value2<0) {
                    scrollView.contentOffset=CGPointMake(0,-value2);
                    value2=0;
                }
                float value=value2+(CDPSHEIGHT-CDPMaxY(scrollView)-_topHeight);
                
                [UIView animateWithDuration:0.3 animations:^{
                    _superView.transform=CGAffineTransformMakeTranslation(0,value-height-_valueOfHigher);
                }];
            }
        }
    }
}











@end
