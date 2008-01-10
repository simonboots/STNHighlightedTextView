#import "HighlightDelegate.h"
#import "lextokens.h"

@implementation HighlightDelegate

- (void)textDidChange:(NSNotification *)aNotification
{

    
    NSTextView *textview = [aNotification object];
    NSTextStorage *textstorage = [textview textStorage];
    NSAttributedString *attrString = [textstorage attributedSubstringFromRange:NSMakeRange(0, [[textstorage string] length])];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attrString];
    
    extern char *yytext;
    NSUInteger pos = 0;
    NSInteger token;
    
    // Save current cursor position
    NSUInteger cursorPos = [textview selectedRange].location;

    NSString *temp;
    
    yystatereset(); // reset start condition
        
    [attributedString beginEditing];
    
    // scan string
    yy_scan_string([[attrString string] UTF8String]); 
    
    while (token = yylex()) {
        temp = [NSString stringWithUTF8String:yytext];
        NSRange range = NSMakeRange(pos, [temp length]);

        NSColor *color = [NSColor blackColor]; // default color
        
        switch(token) {
            case TEXT:
            case UTF8CHAR:
                color = [NSColor blueColor];
                break;
            case REAL:
                color = [NSColor redColor];
                break;
            case QUOTEDREAL:
                color = [NSColor greenColor];
                break;
        }
        
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:color
                                 range:range];

        pos += [temp length];
    }
    
    [attributedString endEditing];
    
    [[textview textStorage] setAttributedString:attributedString];
    [attributedString release];
    [textview setSelectedRange:NSMakeRange(cursorPos, 0)];
}
@end
