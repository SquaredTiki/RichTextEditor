//
//  RTEGestureRecognizer.m
//  RichTextEditor
//
//  Created by Joshua Garnham on 27/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RTEGestureRecognizer.h"

@implementation RTEGestureRecognizer
@synthesize touchesBeganCallback, touchesEndedCallback;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touchesBeganCallback)
        touchesBeganCallback(touches, event);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touchesEndedCallback)
        touchesEndedCallback(touches, event); 
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
    if ([[preventingGestureRecognizer description] rangeOfString:@"UIScrollViewPanGestureRecognizer"].location != NSNotFound)
        return NO;
    return [super canBePreventedByGestureRecognizer:preventingGestureRecognizer];
}

@end
