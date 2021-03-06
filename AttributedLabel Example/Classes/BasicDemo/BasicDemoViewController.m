//
//  BasicDemoViewController.m
//  AttributedLabel Example
//
//  Created by Olivier Halligon on 31/08/12.
//
//

#import "BasicDemoViewController.h"
#import "UIAlertView+Commodity.h"

#import "NSAttributedString+Attributes.h"
#import "OHASBasicHTMLParser.h"
#import "OHASBasicMarkupParser.h"

@interface BasicDemoViewController ()
@property(nonatomic, retain) NSMutableSet* visitedLinks;
@end

@implementation BasicDemoViewController
@synthesize demoLabel = _demoLabel;
@synthesize htmlLabel = _htmlLabel;
@synthesize basicMarkupLabel = _basicMarkupLabel;
@synthesize visitedLinks = _visitedLinks;

/////////////////////////////////////////////////////////////////////////////
#pragma mark - Init/Dealloc
/////////////////////////////////////////////////////////////////////////////


-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.visitedLinks = [NSMutableSet set];
    }
    return self;
}

#if ! __has_feature(objc_arc)
-(void)dealloc
{
    [_visitedLinks release];
    [_demoLabel release];
    [_htmlLabel release];
    [_basicMarkupLabel release];
    [super dealloc];
}
#endif

-(void)viewDidLoad
{
	[self fillDemoLabel];
    self.htmlLabel.attributedText = [OHASBasicHTMLParser attributedStringByProcessingMarkupInAttributedString:self.htmlLabel.attributedText];
    self.basicMarkupLabel.attributedText = [OHASBasicMarkupParser attributedStringByProcessingMarkupInAttributedString:self.basicMarkupLabel.attributedText];
    [super viewDidLoad];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    self.htmlLabel = nil;
    self.basicMarkupLabel = nil;
    self.demoLabel = nil;
}


/////////////////////////////////////////////////////////////////////////////
#pragma mark - Demo Label : Alignment, Size, etc
/////////////////////////////////////////////////////////////////////////////


-(IBAction)fillDemoLabel
{
	// Suppose you already have set the following properties of the myAttributedLabel object in InterfaceBuilder:
	// - 'text' set to "Hello World!"
	// - fontSize set to 12, text color set to gray
	
	/**(1)** Build the NSAttributedString *******/
	NSMutableAttributedString* attrStr = [self.demoLabel.attributedText mutableCopy];
    
    [attrStr setTextAlignment:kCTCenterTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
	// and only change the color of "Hello"
	[attrStr setTextColor:[UIColor redColor] range:NSMakeRange(26,5)];
	
	/**(2)** Affect the NSAttributedString to the OHAttributedLabel *******/
	self.demoLabel.attributedText = attrStr;
	// "Hello World!" will be displayed in the label, justified, "Hello" in red and " World!" in gray.
	self.demoLabel.automaticallyAddLinksForType = NSTextCheckingTypeDate|NSTextCheckingTypeAddress|NSTextCheckingTypeLink|NSTextCheckingTypePhoneNumber;
    self.demoLabel.centerVertically = NO;
    
#if ! __has_feature(objc_arc)
	[attrStr release];
#endif
}


-(IBAction)changeHAlignment
{
    // NOTE: You could use label2.textAlignment but this does not support the "Justified" text alignement
    // label2.textAlignment = ( (int)label2.textAlignment + 1 ) % 3;
    // So we prefer to set the CTTextAlignment on the whole NSAttributedString instead
    
    
    NSMutableAttributedString* attrStr = [self.demoLabel.attributedText mutableCopy];
    
    CTTextAlignment textAlign = [attrStr textAlignmentAtIndex:0 effectiveRange:NULL];
    textAlign = (CTTextAlignment)  ( ((int)textAlign + 1) % 4 ); // loop thru enum values 0 to 3 (left, center, right, justified)
    [attrStr setTextAlignment:textAlign lineBreakMode:kCTLineBreakByWordWrapping];
    
    self.demoLabel.attributedText = attrStr;
#if ! __has_feature(objc_arc)
	[attrStr release];
#endif
}

-(IBAction)changeVAlignment
{
	self.demoLabel.centerVertically = !self.demoLabel.centerVertically;
}

-(IBAction)changeSize
{
	CGRect r = self.demoLabel.frame;
	r.size.width = 500 - r.size.width; // switch between 200 and 300px
	self.demoLabel.frame = r;
}

-(IBAction)resetVisitedLinks
{
	[self.visitedLinks removeAllObjects];
	[self.demoLabel setNeedsRecomputeLinksInText];
}


/////////////////////////////////////////////////////////////////////////////
#pragma mark - Visited Links Managment
/////////////////////////////////////////////////////////////////////////////


id objectForLinkInfo(NSTextCheckingResult* linkInfo)
{
	// Return the first non-nil property
	return (id)linkInfo.URL ?: (id)linkInfo.phoneNumber ?: (id)linkInfo.addressComponents ?: (id)linkInfo.date ?: (id)[linkInfo description];
}

-(UIColor*)attributedLabel:(OHAttributedLabel*)attrLabel colorForLink:(NSTextCheckingResult*)link underlineStyle:(int32_t*)pUnderline
{
	if ([self.visitedLinks containsObject:objectForLinkInfo(link)]) {
		// Visited link
		*pUnderline = kCTUnderlineStyleSingle|kCTUnderlinePatternDot;
		return [UIColor purpleColor];
	} else {
		*pUnderline = attrLabel.linkUnderlineStyle; // use default value
		return attrLabel.linkColor; // use default value
	}
}

-(BOOL)attributedLabel:(OHAttributedLabel *)attributedLabel shouldFollowLink:(NSTextCheckingResult *)linkInfo
{
	[self.visitedLinks addObject:objectForLinkInfo(linkInfo)];
	[attributedLabel setNeedsRecomputeLinksInText];
	
    if ([[UIApplication sharedApplication] canOpenURL:linkInfo.extendedURL])
    {
        // use default behavior
        return YES;
    }
    else
    {
        switch (linkInfo.resultType) {
            case NSTextCheckingTypeAddress:
                [UIAlertView showWithTitle:@"Address" message:[linkInfo.addressComponents description]];
                break;
            case NSTextCheckingTypeDate:
                [UIAlertView showWithTitle:@"Date" message:[linkInfo.date description]];
                break;
            case NSTextCheckingTypePhoneNumber:
                [UIAlertView showWithTitle:@"Phone Number" message:linkInfo.phoneNumber];
                break;
            default: {
                NSString* message = [NSString stringWithFormat:@"You typed on an unknown link type (NSTextCheckingType %lld)",linkInfo.resultType];
                [UIAlertView showWithTitle:@"Unknown link type" message:message];
                break;
            }
        }
        return NO;
    }
}

@end
