//
//  RichTextEditorViewController.m
//  RichTextEditor
//
//  Created by Joshua Garnham on 01/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RichTextEditorViewController.h"

@implementation RichTextEditorViewController
@synthesize webView;
@synthesize timer;

#pragma mark - Additions

- (UIColor *)colorFromRGBValue:(NSString *)rgb { // General format is 'rgb(red, green, blue)'
    if ([rgb rangeOfString:@"rgb"].location == NSNotFound)
        return nil;
    
    NSMutableString *mutableCopy = [rgb mutableCopy];
    [mutableCopy replaceCharactersInRange:NSMakeRange(0, 4) withString:@""];
    [mutableCopy replaceCharactersInRange:NSMakeRange(mutableCopy.length-1, 1) withString:@""];
    
    NSArray *components = [mutableCopy componentsSeparatedByString:@","];
    int red = [[components objectAtIndex:0] intValue];
    int green = [[components objectAtIndex:1] intValue];
    int blue = [[components objectAtIndex:2] intValue];
    
    UIColor *retVal = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
    return retVal;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // Load in the index file
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *indexFileURL = [bundle URLForResource:@"index" withExtension:@"html"];
    [webView loadRequest:[NSURLRequest requestWithURL:indexFileURL]];
    
    // Add ourselves as observer for the keyboard will show notification so we can remove the toolbar
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    // Set up navbar items now
    [self checkSelection:self];
    
    // Set timer to checkSelection every 0.1 seconds
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkSelection:) userInfo:nil repeats:YES];
    
    // Add the highlight menu item to the menu controller
    UIMenuItem *highlightMenuItem = [[UIMenuItem alloc] initWithTitle:@"Highlight" action:@selector(highlight)];
    [[UIMenuController sharedMenuController] setMenuItems:[NSArray arrayWithObject:highlightMenuItem]];
    
    // Setup image dragging/moving
    RTEGestureRecognizer *tapInterceptor = [[RTEGestureRecognizer alloc] init];
    tapInterceptor.touchesBeganCallback = ^(NSSet *touches, UIEvent *event) {
        // Here we just get the location of the touch
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint touchPoint = [touch locationInView:self.view];
        
        // What we do here is to get the element that is located at the touch point to see whether or not it is an image
        NSString *javascript = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).toString()", touchPoint.x, touchPoint.y];
        NSString *elementAtPoint = [webView stringByEvaluatingJavaScriptFromString:javascript]; 
        
        if ([elementAtPoint rangeOfString:@"Image"].location != NSNotFound) {
            // We set the inital point of the image for use latter on when we actually move it
            initialPointOfImage = touchPoint;
            // In order to make moving the image easy we must disable scrolling otherwise the view will just scroll and prevent fully detecting movement on the image.            
            webView.scrollView.scrollEnabled = NO;
        } else {
            initialPointOfImage = CGPointZero;  
        }
    };
    tapInterceptor.touchesEndedCallback = ^(NSSet *touches, UIEvent *event) {
        // Let's get the finished touch point
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint touchPoint = [touch locationInView:self.view];
        
        // And move that image!
        NSString *javascript = [NSString stringWithFormat:@"moveImageAtTo(%f, %f, %f, %f)", initialPointOfImage.x, initialPointOfImage.y, touchPoint.x, touchPoint.y];
        [webView stringByEvaluatingJavaScriptFromString:javascript];
        
        // All done, lets re-enable scrolling
        webView.scrollView.scrollEnabled = YES;
    };
    [webView.scrollView addGestureRecognizer:tapInterceptor];
}


- (void)checkSelection:(id)sender {    
    NSString *currentColor = [webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandValue('backColor')"];
    BOOL isYellow = [currentColor isEqualToString:@"rgb(255, 255, 0)"];
    UIMenuItem *highlightMenuItem = [[UIMenuItem alloc] initWithTitle:(isYellow) ? @"De-Highlight" : @"Highlight" action:@selector(highlight)];
    [[UIMenuController sharedMenuController] setMenuItems:[NSArray arrayWithObject:highlightMenuItem]];
    

    BOOL boldEnabled = [[webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('Bold')"] boolValue];
    BOOL italicEnabled = [[webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('Italic')"] boolValue];
    BOOL underlineEnabled = [[webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('Underline')"] boolValue];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *bold = [[UIBarButtonItem alloc] initWithTitle:(boldEnabled) ? @"[B]" : @"B" style:UIBarButtonItemStyleBordered target:self action:@selector(bold)];
    UIBarButtonItem *italic = [[UIBarButtonItem alloc] initWithTitle:(italicEnabled) ? @"[I]" : @"I" style:UIBarButtonItemStyleBordered target:self action:@selector(italic)];
    UIBarButtonItem *underline = [[UIBarButtonItem alloc] initWithTitle:(underlineEnabled) ? @"[U]" : @"U" style:UIBarButtonItemStyleBordered target:self action:@selector(underline)];
    
    [items addObject:underline];
    [items addObject:italic];
    [items addObject:bold];
    
    if (currentBoldStatus != boldEnabled || currentItalicStatus != italicEnabled || currentUnderlineStatus != underlineEnabled || sender == self) {
        self.navigationItem.rightBarButtonItems = items;
        currentBoldStatus = boldEnabled;
        currentItalicStatus = italicEnabled;
        currentUnderlineStatus = underlineEnabled;
    }
    
    // Left items now
    
    [items removeAllObjects];
    
    UIBarButtonItem *plusFontSize = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStyleBordered target:self action:@selector(fontSizeUp)];
    UIBarButtonItem *minusFontSize = [[UIBarButtonItem alloc] initWithTitle:@"-" style:UIBarButtonItemStyleBordered target:self action:@selector(fontSizeDown)];
    
    int size = [[webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandValue('fontSize')"] intValue];
    if (size == 7)
        plusFontSize.enabled = NO;
    else if (size == 1)
        minusFontSize.enabled = NO;
    
    [items addObject:plusFontSize];
    [items addObject:minusFontSize];
    
    // Font Color Picker
    UIBarButtonItem *fontColorPicker = [[UIBarButtonItem alloc] initWithTitle:@"Color" style:UIBarButtonItemStyleBordered target:self action:@selector(displayFontColorPicker:)];
    
    NSString *foreColor = [webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandValue('foreColor')"];
    UIColor *color = [self colorFromRGBValue:foreColor];
    if (color)
        [fontColorPicker setTintColor:color];
    
    [items addObject:fontColorPicker];
    
    // Font Picker
    UIBarButtonItem *fontPicker = [[UIBarButtonItem alloc] initWithTitle:@"Font" style:UIBarButtonItemStyleBordered target:self action:@selector(displayFontPicker:)];
    
    NSString *fontName = [webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandValue('fontName')"];
    UIFont *font = [UIFont fontWithName:fontName size:[UIFont systemFontSize]];
    if (font)
        [fontPicker setTitleTextAttributes:[NSDictionary dictionaryWithObject:font forKey:UITextAttributeFont] forState:UIControlStateNormal];
    
    [items addObject:fontPicker];
    
    UIBarButtonItem *undo = [[UIBarButtonItem alloc] initWithTitle:@"Undo" style:UIBarButtonItemStyleBordered target:self action:@selector(undo)];
    UIBarButtonItem *redo = [[UIBarButtonItem alloc] initWithTitle:@"Redo" style:UIBarButtonItemStyleBordered target:self action:@selector(redo)];
    
    BOOL undoAvailable = [[webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandEnabled('undo')"] boolValue];
    BOOL redoAvailable = [[webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandEnabled('redo')"] boolValue];
    
    if (!undoAvailable)
        [undo setEnabled:NO];
    
    if (!redoAvailable)
        [redo setEnabled:NO];
    
    [items addObject:undo];
    [items addObject:redo];
    
    UIBarButtonItem *insertPhoto = [[UIBarButtonItem alloc] initWithTitle:@"Photo+" style:UIBarButtonItemStyleBordered target:self action:@selector(insertPhoto:)];
    [items addObject:insertPhoto];
    
    if (currentFontSize != size || ![currentForeColor isEqualToString:foreColor] || ![currentFontName isEqualToString:fontName] || currentUndoStatus != undoAvailable || currentRedoStatus != redoAvailable || sender == self) {
        self.navigationItem.leftBarButtonItems = items;
        currentFontSize = size;
        currentForeColor = [foreColor retain];
        currentFontName = [fontName retain];
        currentUndoStatus = undoAvailable;
        currentRedoStatus = redoAvailable;
    }
}

#pragma mark Removing toolbar

- (void)keyboardWillShow:(NSNotification *)note {
    [self performSelector:@selector(removeBar) withObject:nil afterDelay:0];
}

- (void)removeBar {
    // Locate non-UIWindow.
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if (![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    
    // Locate UIWebFormView.
    for (UIView *possibleFormView in [keyboardWindow subviews]) {       
        // iOS 5 sticks the UIWebFormView inside a UIPeripheralHostView.
        if ([[possibleFormView description] rangeOfString:@"UIPeripheralHostView"].location != NSNotFound) {
            for (UIView *subviewWhichIsPossibleFormView in [possibleFormView subviews]) {
                if ([[subviewWhichIsPossibleFormView description] rangeOfString:@"UIWebFormAccessory"].location != NSNotFound) {
                    [subviewWhichIsPossibleFormView removeFromSuperview];
                }
            }
        }
    }
}

#pragma mark Inserting photos

- (void)insertPhoto:(id)sender {    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; 
    imagePicker.delegate = self; 
    
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
    [popover presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    imagePickerPopover = popover;
    
    [imagePicker release];
}

static int i = 0;

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // Obtain the path to save to
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"photo%i.png", i]];
    
    // Extract image from the picker and save it
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];   
    if ([mediaType isEqualToString:@"public.image"]){
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSData *data = UIImagePNGRepresentation(image);
        [data writeToFile:imagePath atomically:YES];
    }
    
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('insertImage', false, '%@')", imagePath]];
    [imagePickerPopover dismissPopoverAnimated:YES];
    i++;
}

#pragma mark Undo/Redo

- (void)undo {
    [webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('undo')"];
}

- (void)redo {
    [webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('redo')"];
}

#pragma mark Fonts

- (void)displayFontColorPicker:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select a font color" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Blue", @"Yellow", @"Green", @"Red", @"Orange", nil];
    [actionSheet showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
}

- (void)displayFontPicker:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select a font" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Helvetica", @"Courier", @"Arial", @"Zapfino", @"Verdana", nil];
    [actionSheet showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *selectedButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    selectedButtonTitle = [selectedButtonTitle lowercaseString];
    
    if ([actionSheet.title isEqualToString:@"Select a font"])
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('fontName', false, '%@')", selectedButtonTitle]];
    else
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('foreColor', false, '%@')", selectedButtonTitle]];
}

- (void)fontSizeUp {
    [timer invalidate]; // Stop it while we work
    
    int size = [[webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandValue('fontSize')"] intValue] + 1;
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('fontSize', false, '%i')", size]]; 
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkSelection:) userInfo:nil repeats:YES];
}

- (void)fontSizeDown {
    [timer invalidate]; // Stop it while we work
    
    int size = [[webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandValue('fontSize')"] intValue] - 1;    
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('fontSize', false, '%i')", size]];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkSelection:) userInfo:nil repeats:YES];
}

#pragma mark B/I/U

- (void)bold {
    [webView stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"Bold\")"];
}

- (void)italic {
    [webView stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"Italic\")"];
}

- (void)underline {
    [webView stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"Underline\")"];
}

#pragma Highlights

- (void)highlight {
    NSString *currentColor = [webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandValue('backColor')"];
    if ([currentColor isEqualToString:@"rgb(255, 255, 0)"]) {
        [webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('backColor', false, 'white')"];
    } else {
        [webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('backColor', false, 'yellow')"];
    }
}

@end
