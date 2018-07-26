//
//  KXSlideCardView.h
//  kxd
//
//  Created by 刘雨笛 on 2018/6/20.
//

#import <UIKit/UIKit.h>

@class KXSlideCardView;
@protocol KXSlideCardViewDelegate <NSObject>

@required
- (NSInteger)numberOfCard:(KXSlideCardView *)slideCardView;

@optional
- (UIView *)slideCardView:(KXSlideCardView *)slideCardView viewForIndex:(NSInteger)index;

- (void)onClickCard:(KXSlideCardView *)slideCardView;

- (void)willSlideToEnd:(KXSlideCardView *)slideCardView;

@end

@interface KXSlideCardView : UIView

@property (nonatomic, weak) id <KXSlideCardViewDelegate> delegate;

@property (nonatomic, assign) CGSize cardSize;
@property (nonatomic, assign) NSInteger viewCount;
@property (nonatomic, assign) CGPoint cardCenter;
@property (nonatomic, assign) NSInteger currentIndex;

- (void)reloadData;

- (void)registerClass:(Class)viewClass;

- (__kindof UIView *)dequeueViewAtIndex:(NSInteger)index;

@end
