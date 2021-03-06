/*
Copyright (c) 2010-2011, Peter Hajas
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Peter Hajas nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PETER HAJAS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <QuartzCore/QuartzCore.h>
#import "MNAlertDashboardViewController.h"

@implementation MNAlertDashboardViewController

@synthesize window;
@synthesize delegate = _delegate;

-(id)initWithDelegate:(id)__delegate;
{
    self = [super init];

    if (self)
    {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];

        _delegate = __delegate;

        // window:
        window = [[UIWindow alloc]
        initWithFrame:CGRectMake(0,0,screenBounds.size.width,screenBounds.size.height)];

        window.windowLevel = UIWindowLevelAlert+102.0f;
        window.userInteractionEnabled = YES;
        window.hidden = YES;

        // button to return to the application
        returnToApplicationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        returnToApplicationButton.frame = CGRectMake(0.0, 0.0, 320.0, 480.0);
        [returnToApplicationButton setAlpha:1.0];

        // wire up the button!
        [returnToApplicationButton addTarget:self action:@selector(dismissSwitcher:)
                 forControlEvents:UIControlEventTouchUpInside];

        // Table View Data Source
        tableViewDataSourceEditable = [[MNAlertTableViewDataSourceEditable alloc] initWithStyle:kMNAlertTableViewDataSourceTypePending
                                                                                    andDelegate:_delegate];

        // Create the tableview
        alertListView = [[UITableView alloc] initWithFrame:CGRectMake(16.5,112,287,325) style:UITableViewStylePlain];
        alertListView.delegate = self;
        alertListView.dataSource = tableViewDataSourceEditable;
        [alertListView setAlpha:1.0];
        alertListView.backgroundColor = [UIColor whiteColor];
        alertListView.layer.cornerRadius = 10;

        // Dashboard background
        dashboardBackground = [[UIView alloc] initWithFrame:CGRectMake(0,0,screenBounds.size.width,screenBounds.size.height)];
        [dashboardBackground setBackgroundColor:[UIColor blackColor]];
        [dashboardBackground setAlpha:0.75];

        // ClearAllButton
        clearAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
        clearAllButton.frame = CGRectMake(80,427,160,60);
        [clearAllButton setTitle:@"Clear pending" forState: UIControlStateNormal];
        [clearAllButton setAlpha:1.0];
        clearAllButton.titleLabel.font          = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        clearAllButton.titleLabel.textAlignment = UITextAlignmentCenter;
        clearAllButton.titleLabel.textColor     = [UIColor whiteColor];
        clearAllButton.titleLabel.shadowColor   = [UIColor blackColor];
        clearAllButton.titleLabel.shadowOffset  = CGSizeMake(0,-1);
        clearAllButton.backgroundColor          = [UIColor clearColor];

        // Wire up clearAllButton
        [clearAllButton addTarget:self action:@selector(clearDashboardPushed:)
                 forControlEvents:UIControlEventTouchUpInside];

        // Add everything to the view
        dashboardShowing = NO;
        [window addSubview:dashboardBackground];
        [window addSubview:returnToApplicationButton];
        [window addSubview:alertListView];
        [window addSubview:clearAllButton];

        // Release stuff we don't need to hang on to
        [alertListView release];
        // [dashboardBackground release];

        [UIView setAnimationDidStopSelector:@selector(animationDidStop:didFinish:inContext:)];
    }

    return self;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Take action on the alert
    [_delegate actionOnAlertAtIndex:indexPath.row];
}

-(void)refresh
{
    [alertListView reloadData];
}

-(void)dismissSwitcher:(id)sender
{
    [_delegate dismissSwitcher];
}

-(void)toggleDashboard
{
    if (dashboardShowing)
    {
        [self fadeDashboardDown];
    }
    else
    {
        [self showDashboard];
    }
}

// ---------------------------------------------------
// Animate dashboard elements down for a "fade down"
// effect similar to the multitasking drawer animation
// ---------------------------------------------------
-(void)fadeDashboardDown
{
    window.userInteractionEnabled = NO;
    dashboardShowing              = NO;

    [UIView beginAnimations:@"fadeDashboardDown" context:NULL];
      [UIView setAnimationDuration:0.25];
      [window setFrame:CGRectMake(0,0,320,480)];
      [window setAlpha:0.0];
      [clearActionSheet dismissWithClickedButtonIndex:1 animated:YES];
    [UIView commitAnimations];
}

// -----------------------------------------------
// Animate dashboard elements using a "fade away"
// effect to better match the app switching effect
// -----------------------------------------------
-(void)fadeDashboardAway
{
    window.userInteractionEnabled = NO;
    dashboardShowing              = NO;

    [UIView beginAnimations:@"fadeDashboardAway" context:NULL];
      [UIView setAnimationDuration:0.135];

      // Shrink the elements and fade out
      // to create a zoom out effect
      alertListView.transform  = CGAffineTransformMakeScale(0.1,0.1);
      clearAllButton.transform = CGAffineTransformMakeScale(0.1,0.1);

      [window setAlpha:0.0];
    [UIView commitAnimations];
    [window setFrame:CGRectMake(0,0,320,480)];
}

// -----------------------------------------------
// Animate the dashboard elements "up" similar to
// the multitasking drawer animation to make room
// for the application switcher
// -----------------------------------------------
-(void)showDashboard
{
    window.userInteractionEnabled = YES;
    window.hidden                 = NO;
    dashboardShowing              = YES;

    // Restore previously transformed elements
    alertListView.transform  = CGAffineTransformIdentity;
    clearAllButton.transform = CGAffineTransformIdentity;

    [UIView beginAnimations:@"fadeIn" context:NULL];
      [UIView setAnimationDuration:0.25];
      [window setFrame:CGRectMake(0,-92,320,480)];
      [window setAlpha:1.0];
    [UIView commitAnimations];
}

-(void)clearDashboardPushed:(id)sender
{
    //Let's create a UIActionSheet to deal with this very destructive action
    clearActionSheet = [[UIActionSheet alloc] initWithTitle:@"Clear pending alerts?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:@"Clear pending"
                                          otherButtonTitles:nil];

    // Temporarily reposition window and elements
    // to cover up the application switcher drawer
    [window setFrame:CGRectMake(0,0,320,480)];
    [alertListView setFrame:CGRectMake(16,20,287,322)];
    [clearAllButton setAlpha:0];

    // Show the sheet
    if ([clearActionSheet respondsToSelector:@selector(showInView:)])
    {
        [clearActionSheet removeFromSuperview];
        [clearActionSheet showInView:window];
        [clearActionSheet setFrame:CGRectMake(0,300,320,185)];
        [window addSubview:clearActionSheet];
    }
    else
    {
        // If they're on an older device, do some fancy
        // footwork to get the UIActionSheet to show up
        [clearActionSheet showInView:window];
        [clearActionSheet setFrame:CGRectMake(0,300,320,185)];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    bool didClear = NO;
    if (buttonIndex == 0)
    {
        // Clear notifications!
        [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
        [_delegate clearPending];
        // Hide the dashboard view
        didClear = YES;
    }
    else if (buttonIndex == 1)
    {
        // Don't do anything!
        [actionSheet dismissWithClickedButtonIndex:1 animated:YES];
    }
    
    if(didClear)
    {
        [self fadeDashboardAway];
    }
    else
    {
        [clearAllButton setAlpha:1.0];
    }
    
    // Restore window and elements to original positions
    [window setFrame:CGRectMake(0,-92,320,480)];
    [alertListView setFrame:CGRectMake(16,112,287,322)];
}

-(void)animationDidStop:(NSString*)animationID didFinish:(NSNumber*)finished inContext:(id)context
{
    if ([animationID isEqualToString:@"fadeIn"])
    {
        window.userInteractionEnabled = YES;
    }
    if ([animationID isEqualToString:@"fadeDashboardDown"] || [animationID isEqualToString:@"fadeDashboardAway"])
    {
        window.userInteractionEnabled = NO;
        window.hidden = YES;
    }
}

-(bool)isShowing
{
    return dashboardShowing;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableViewDataSourceEditable tableView:tableView heightForRowAtIndexPath:indexPath];
}

@end

