//
//  UIWebView+PGAdditions.h
//
//  Vertical layout manager for PhoneGap, for on-screen views. 
//  y-order management (think of blocks in a stack, shuffled around and resized to fill available space)
//  Only cares about heights of UIViews so it fills the full screen height of the device.
//
//  All animation arguments are treated as 'NO' for now.
//

#import <Foundation/Foundation.h>

typedef enum {
	PGLayoutPositionUnknown = -1,
	PGLayoutPositionTop = 0,
	//PGLayoutPositionMiddle, //  always taken up by UIWebView (currently)
	PGLayoutPositionBottom
	
} PGLayoutPosition;


@interface  UIWebView (PGLayoutAdditions)

/*
 * Adds a sibling UIView for the UIWebView.
 *
 * Pushes up any sibling UIView at that position. 
 * Animation not currently supported.
 */
- (void) pg_addSiblingView:(UIView*) siblingView withPosition:(PGLayoutPosition)position withAnimation:(BOOL)animate;

/*
 * Moves a sibling UIView to the new position
 *
 * Pushes up/down any sibling UIView at that position.
 * Animation not currently supported.
 */
- (void) pg_moveSiblingView:(UIView*) siblingView toPosition:(PGLayoutPosition)position withAnimation:(BOOL)animate;

/*
 * Removes a sibling UIView.
 *
 * Animation not currently supported.
 */
- (void) pg_removeSiblingView:(UIView*) siblingView withAnimation:(BOOL)animate;


/*
 * Returns true if the sibling view exists.
 *
 */
- (BOOL) pg_hasSiblingView:(UIView*) siblingView;

/*
 * Re-lays out all the sibling UIViews to fill the available height.
 *
 * Animation not currently supported.
 */
- (void) pg_relayout:(BOOL)animate;

/*
 * Finds out the position of the sibling view in relation to the another view (helper)
 *
 */
- (PGLayoutPosition) pg_layoutPositionOfView:(UIView*)siblingView fromView:(UIView*)fromView;


/*
 * Finds out the position of the sibling view in relation to the middle UIWebView.
 *
 */
- (PGLayoutPosition) pg_layoutPosition:(UIView*)siblingView;

/*
 * Returns true if any of the sibling UIViews are intersecting with each other.
 *
 */
- (BOOL) pg_viewsAreIntersecting;

@end
