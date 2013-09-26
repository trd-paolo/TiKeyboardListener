//
//   Copyright 2012 jordi domenech <jordi@iamyellow.net>
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import "NetIamyellowTikeyboardlistenerView.h"
#import "TiUIWindow.h"
#import "TiUIWindowProxy.h"

#import "TiUIScrollView.h"
#import "TiUIScrollViewProxy.h"

#import <TiUtils.h>
#import <TiUIWindow.h>
#import <TiUIWindowProxy.h>

@implementation NetIamyellowTikeyboardlistenerView

-(id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
	return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    [super dealloc];
}

#pragma mark View init

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    if (!ourProxy) {
        ourProxy = (NetIamyellowTikeyboardlistenerViewProxy*)[self proxy];
        
        // must fill entire container height
        CGRect frame = self.frame;
        frame.origin.y = 0.0f;
        frame.size.height = self.superview.frame.size.height;
        [TiUtils setView:self positionRect:frame];
        
        [ourProxy setTop:NUMINT(0)];
        [ourProxy setHeight:kTiBehaviorFill];
        
        currentHeight = -1;
    }
}

#pragma Keyboard listener

-(void)fireKeyboardEvent
{
    if (!showEvent) {
        [ourProxy setHeight:kTiBehaviorFill];
    }
    
    if ( (showEvent && [ourProxy _hasListeners:@"keyboard:show"]) || (!showEvent && [ourProxy _hasListeners:@"keyboard:hide"]) ) {
        CGRect frame = self.frame;
        NSMutableDictionary* event = [NSMutableDictionary dictionary];
        [event setObject:NUMFLOAT(keyboardHeight) forKey:@"keyboardHeight"];
        [event setObject:NUMFLOAT(frame.size.height) forKey:@"height"];
        [ourProxy fireEvent:showEvent ? @"keyboard:show" : @"keyboard:hide" withObject:event];
    }
}

-(CGFloat)getTabBarHeight
{
    // look into view's hierarchy until find tab bar controller
    // => the view is inside a window inside a tab group
    id parent = self.superview;
    UITabBar* tabBar = nil;
    while (parent != nil && tabBar == nil) {
        if ([[parent nextResponder] isKindOfClass:[UIViewController class]]) {
            UIViewController* parentViewController = (UIViewController*)[parent nextResponder];
            if (parentViewController.tabBarController != nil) {
                tabBar = parentViewController.tabBarController.tabBar;
            }
        }
        parent = ((UIView*)parent).superview;
    }
    
    // if we're inside a tabgroup, let's see if the container window has tabBarHidden = true
    BOOL ignoreTabBar = NO;
    if (tabBar != nil) {
        parent = self.superview;
        BOOL windowProxyFfound = NO;
        while (parent != nil && !windowProxyFfound) {
            if ([parent isKindOfClass:[TiUIWindow class]]) {
                TiUIWindow* parentAsAWindow = (TiUIWindow*)parent;
                TiUIWindowProxy* parentAsAWindowProxy = (TiUIWindowProxy*)parentAsAWindow.proxy;
                id tabBarHiddenRawValue = [parentAsAWindowProxy valueForKey:@"tabBarHidden"];
                if (tabBarHiddenRawValue) {
                    NSNumber* tabBarHidden = tabBarHiddenRawValue;
                    if ([tabBarHidden integerValue] == 1) {
                        ignoreTabBar = YES;
                    }
                }
            }
            parent = ((UIView*)parent).superview;
        }
    }
    
    return tabBar == nil || ignoreTabBar ? 0.0f : tabBar.frame.size.height;
}

-(void)keyboardWillShow:(NSNotification*)note
{
    CGFloat tabbarHeight = [self getTabBarHeight];
    
    NSDictionary* userInfo = note.userInfo;
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    CGRect keyboardFrameBegin = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect keyboardFrameEnd = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL portrait = orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown;
    keyboardHeight = portrait ? keyboardFrameEnd.size.height : keyboardFrameEnd.size.width;

    NSInteger way;
    // APPEARS FROM BOTTOM TO TOP
    if (portrait && keyboardFrameBegin.origin.x == keyboardFrameEnd.origin.x) { 
        way = 0;
    }
    else if (!portrait && keyboardFrameBegin.origin.y == keyboardFrameEnd.origin.y) { 
        way = 1;
    }        
    // APPEARS FROM RIGHT TO LEFT (NAVIGATION CONTROLLER, OPENING WINDOW)
    else if (portrait && keyboardFrameBegin.origin.y == keyboardFrameEnd.origin.y) { 
        way = 2;
    }
    else if (!portrait && keyboardFrameBegin.origin.x == keyboardFrameEnd.origin.x) { 
        way = 3;
    }
    
    if (currentHeight < 0 || currentHeight != self.frame.size.height) {
        currentHeight = self.superview.frame.size.height;
    }
    
    currentHeight -= keyboardHeight;
    currentHeight += tabbarHeight;
    
    if (way < 2) {
        // if the first child is a scroll view, animate the contentInset to avoid unwanted jumps
        id possibleScrollView = [[self subviews] objectAtIndex:0];
        if ([possibleScrollView isKindOfClass:[TiUIScrollView class]]) {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
                TiUIScrollViewImpl* sv = [(TiUIScrollView*)possibleScrollView scrollView];
                UIEdgeInsets newInset = sv.contentInset;
                newInset.bottom = keyboardHeight - tabbarHeight;
                sv.contentInset = newInset;
                [sv setScrollIndicatorInsets:newInset];
            } completion:^(BOOL finished) {
            }];
        }
        else {
            NSMutableDictionary* anim = [NSMutableDictionary dictionary];
            [anim setObject:NUMFLOAT(currentHeight) forKey:@"height"];
            
            NSInteger delay = 0;
            if (tabbarHeight != 0) {
                delay = 50;
            }

            [anim setObject:NUMINT((duration * 1000) - delay) forKey:@"duration"];
            [anim setObject:NUMINT(delay) forKey:@"delay"];
            [anim setObject:NUMINT(0) forKey:@"curve"];
            
            [ourProxy animate:anim];
        }
        
        showEvent = YES;
        [self performSelector:@selector(fireKeyboardEvent)
                   withObject:self
                   afterDelay:duration];
    }
    else {
        id possibleScrollView = [[self subviews] objectAtIndex:0];
        if ([possibleScrollView isKindOfClass:[TiUIScrollView class]]) {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
                TiUIScrollViewImpl* sv = [(TiUIScrollView*)possibleScrollView scrollView];
                UIEdgeInsets newInset = sv.contentInset;
                newInset.bottom = keyboardHeight - tabbarHeight;
                sv.contentInset = newInset;
                [sv setScrollIndicatorInsets:newInset];
            } completion:^(BOOL finished) {
            }];
        }
        else {
            CGRect frame = self.frame;
            frame.size.height = currentHeight;

            [TiUtils setView:self positionRect:frame];
            [ourProxy setHeight:NUMFLOAT(currentHeight)];
        }

        if ([ourProxy _hasListeners:@"keyboard:show"]) {
            NSMutableDictionary* event = [NSMutableDictionary dictionary];
            [event setObject:NUMFLOAT(keyboardHeight) forKey:@"keyboardHeight"];
            [event setObject:NUMFLOAT(currentHeight) forKey:@"height"];
            [ourProxy fireEvent:@"keyboard:show" withObject:event];
        }
    }
}

-(void)keyboardWillHide:(NSNotification *)note
{    
    CGFloat tabbarHeight = [self getTabBarHeight];

    NSDictionary* userInfo = note.userInfo;
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    CGRect keyboardFrameBegin = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect keyboardFrameEnd = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL portrait = orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown;    
    keyboardHeight = portrait ? keyboardFrameEnd.size.height : keyboardFrameEnd.size.width;

    currentHeight += keyboardHeight;
    currentHeight -= tabbarHeight;
    
    NSInteger way;
    // APPEARS FROM BOTTOM TO TOP
    if (portrait && keyboardFrameBegin.origin.x == keyboardFrameEnd.origin.x) { 
        way = 0;
    }
    else if (!portrait && keyboardFrameBegin.origin.y == keyboardFrameEnd.origin.y) { 
        way = 1;
    }        
    // APPEARS FROM RIGHT TO RIGHT (NAVIGATION CONTROLLER, OPENING WINDOW)
    else if (portrait && keyboardFrameBegin.origin.y == keyboardFrameEnd.origin.y) { 
        way = 2;
    }
    else if (!portrait && keyboardFrameBegin.origin.x == keyboardFrameEnd.origin.x) { 
        way = 3;
    }
    
    if (way < 2) {
        // if the first child is a scroll view, animate the contentInset to avoid unwanted jumps
        id possibleScrollView = [[self subviews] objectAtIndex:0];
        if ([possibleScrollView isKindOfClass:[TiUIScrollView class]]) {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
                TiUIScrollViewImpl* sv = [(TiUIScrollView*)possibleScrollView scrollView];
                UIEdgeInsets newInset = sv.contentInset;
                newInset.bottom = 0;
                sv.contentInset = newInset;
                [sv setScrollIndicatorInsets:newInset];
            } completion:^(BOOL finished) {
            }];
        }
        else {
            NSMutableDictionary* anim = [NSMutableDictionary dictionary];
            [anim setObject:NUMFLOAT(currentHeight) forKey:@"height"];
            
            NSInteger delay = 0;
            if (tabbarHeight != 0) {
                delay = 50;
            }
            
            [anim setObject:NUMINT((duration * 1000) - delay) forKey:@"duration"];
            [anim setObject:NUMINT(delay) forKey:@"delay"];
            [anim setObject:NUMINT(0) forKey:@"curve"];
            
            [ourProxy animate:anim];
        }
        
        showEvent = NO;
        [self performSelector:@selector(fireKeyboardEvent)
                   withObject:self
                   afterDelay:duration];
    }
    else {
        id possibleScrollView = [[self subviews] objectAtIndex:0];
        if ([possibleScrollView isKindOfClass:[TiUIScrollView class]]) {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
                TiUIScrollViewImpl* sv = [(TiUIScrollView*)possibleScrollView scrollView];
                UIEdgeInsets newInset = sv.contentInset;
                newInset.bottom = 0;
                sv.contentInset = newInset;
                [sv setScrollIndicatorInsets:newInset];
            } completion:^(BOOL finished) {
            }];
        }
        else {
            CGRect frame = self.frame;
            frame.size.height = currentHeight;

            [TiUtils setView:self positionRect:frame];
            [ourProxy setHeight:kTiBehaviorFill];
        }
        
        if ([ourProxy _hasListeners:@"keyboard:hide"]) {
            NSMutableDictionary* event = [NSMutableDictionary dictionary];
            [event setObject:NUMFLOAT(keyboardHeight) forKey:@"keyboardHeight"];
            [event setObject:NUMFLOAT(currentHeight) forKey:@"height"];
            [ourProxy fireEvent:@"keyboard:hide" withObject:event];
        }
    }
}

@end
