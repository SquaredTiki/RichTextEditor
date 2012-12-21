//
//  RTEGestureRecognizer.h
//  RichTextEditor
//
//  Created by Joshua Garnham on 27/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^TouchEventBlock)(NSSet * touches, UIEvent * event);

@interface RTEGestureRecognizer : UIGestureRecognizer {
    TouchEventBlock touchesBeganCallback;
    TouchEventBlock touchesEndedCallback;
}
@property(copy) TouchEventBlock touchesBeganCallback;
@property(copy) TouchEventBlock touchesEndedCallback;
@end