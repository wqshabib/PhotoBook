#import "YLTableView.h"

@implementation YLTableView

-(void)awakeFromNib {
    [super awakeFromNib];
    self.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.backgroundColor = [UIColor clearColor];
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

@end
