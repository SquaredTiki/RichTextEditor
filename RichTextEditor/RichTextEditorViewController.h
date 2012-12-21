//
//  RichTextEditorViewController.h
//  RichTextEditor
//
//  Created by Joshua Garnham on 01/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RTEGestureRecognizer.h"

@interface RichTextEditorViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate> {
    NSTimer *timer;
    BOOL currentBoldStatus;
    BOOL currentItalicStatus;
    BOOL currentUnderlineStatus;
    int currentFontSize;
    NSString *currentForeColor;    
    NSString *currentFontName;
    BOOL currentUndoStatus;
    BOOL currentRedoStatus;
    UIPopoverController *imagePickerPopover;
    CGPoint initialPointOfImage;
}
@property (retain, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, retain) NSTimer *timer;
- (void)checkSelection:(id)sender;
@end
