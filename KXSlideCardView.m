//
//  KXSlideCardView.m
//  kxd
//
//  Created by 刘雨笛 on 2018/6/20.
//

#import "KXSlideCardView.h"

#define toleranceAlpha (1.0/self.viewCount)
#define toleranceScale 0.05
#define toleranceTraslation 20

@interface KXSlideCardView ()

@property (nonatomic, strong) NSMutableArray <UIView *> *showViewList;

@property (nonatomic, assign) NSInteger allCardCount;
@property (nonatomic, strong) UIView *willShowView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, assign) BOOL isSlideLeft;
@property (nonatomic, assign) Class viewClass;
@property (nonatomic, strong) NSMutableArray <UIView *> *cacheViewList;
@property (nonatomic, assign) NSInteger cacheCount;
@property (nonatomic, assign) BOOL isSlide;
@property (nonatomic, copy) void (^callback)(void);

@end

@implementation KXSlideCardView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    return self;
}

- (void)initView {
    _currentIndex = 0;
    _allCardCount = 0;
    _viewCount = 0;
    UIPanGestureRecognizer *panGecture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGesture:)];
    [self addGestureRecognizer:panGecture];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGesture:)];
    self.tapGesture = tapGesture;
}

- (void)reloadData {
    WEAKIFYSELF;
    self.callback = ^ {
        STRONGIFYSELF;
        if (self.delegate && [self.delegate respondsToSelector:@selector(numberOfCard:)]) {
            self.allCardCount = [self.delegate numberOfCard:self];
            if (self.allCardCount <= _cacheCount) {
                if (self.allCardCount > 1) {
                    _viewCount = self.allCardCount - 1;
                } else {
                    _viewCount = self.allCardCount;
                }
            } else {
                _viewCount = _cacheCount;
            }
        }
        if (self.allCardCount <= 0) {
            return;
        }
        self.currentIndex %= self.allCardCount;
        NSInteger maxIndex = self.currentIndex + self.viewCount - 1;
        if (self.delegate && [self.delegate respondsToSelector:@selector(slideCardView:viewForIndex:)]) {
            for (NSInteger index = self.currentIndex; index <= maxIndex; index++) {
                UIView *view = [self getNewViewAtIndex:index];
                if (![self.showViewList containsObject:view]) {
                    [self.showViewList addObject:view];
                }
                view.frame = CGRectMake(0, 0, self.cardSize.width, self.cardSize.height);
                view.center = self.cardCenter;
                CGFloat alpha = 1-(index - self.currentIndex)*toleranceAlpha;
                view.alpha = alpha;
                CGFloat scale = 1-(index - self.currentIndex)*toleranceScale;
                CGFloat traslation = (index - self.currentIndex)*toleranceTraslation;
                view.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeTranslation(0, traslation));
                [self insertSubview:view atIndex:0];
            }
            [self.showViewList.firstObject addGestureRecognizer:self.tapGesture];
        }
    };
    if (!self.isSlide) {
        self.callback();
        self.callback = nil;
    }
}

- (void)registerClass:(Class)viewClass {
    self.viewClass = viewClass;
}

- (UIView *)dequeueViewAtIndex:(NSInteger)index {
    NSInteger currectIndex = self.currentIndex;
    
    UIView *showView;
    if ((index >= currectIndex && index < currectIndex + self.showViewList.count)||(currectIndex + (NSInteger)self.showViewList.count - self.allCardCount > index)) {
        NSInteger arrayIndex = index - self.currentIndex;
        if (arrayIndex < 0) {
            arrayIndex += self.allCardCount;
        }
        showView = [self.showViewList objectAtIndex:arrayIndex];
    } else if (self.cacheViewList.count) {
        UIView *view = self.cacheViewList.lastObject;
        [self.cacheViewList removeObject:view];
        showView = view;
    } else {
        showView = [[self.viewClass alloc] init];
    }
    showView.transform = CGAffineTransformIdentity;
    return showView;
}

#pragma mark - action
- (void)onPanGesture:(UIPanGestureRecognizer *)panGesture {
    if (self.allCardCount <= 1) {
        return;
    }
    CGPoint translation = [panGesture translationInView:self];
    CGFloat percentage = translation.x/(self.frame.size.width/5);
    percentage = MIN(MAX(percentage, -1), 1);
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        self.isSlide = YES;
        self.isSlideLeft = [panGesture velocityInView:self].x < 0;
        if (self.isSlideLeft) {
            self.willShowView = [self getNewViewAtIndex:self.currentIndex + self.showViewList.count];
        } else {
            self.willShowView = [self getNewViewAtIndex:self.currentIndex - 1];
        }
        if (self.willShowView) {
            if (self.isSlideLeft) {
                CGFloat alpha = 1-((self.viewCount - 1) * toleranceAlpha);
                CGFloat scale = 1-((self.viewCount - 1)*toleranceScale);
                CGFloat traslation = (self.viewCount - 1)*toleranceTraslation;
                self.willShowView.alpha = alpha;
                self.willShowView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeTranslation(0, traslation));
                [self insertSubview:self.willShowView atIndex:0];
            } else {
                self.willShowView.transform = CGAffineTransformMakeTranslation(-self.cardSize.width - ([UIScreen mainScreen].bounds.size.width - self.cardSize.width)/2, 0);
                [self addSubview:self.willShowView];
            }
        }
    } else if (panGesture.state == UIGestureRecognizerStateChanged) {
        if (self.isSlideLeft) {
            UIView *view = self.showViewList.firstObject;
            view.transform = CGAffineTransformMakeTranslation(translation.x, 0);
        } else {
            self.willShowView.transform = CGAffineTransformMakeTranslation(-self.cardSize.width - ([UIScreen mainScreen].bounds.size.width - self.cardSize.width)/2 + translation.x, 0);
        }
        [self onViewShow:percentage];
    } else {
        if (self.willShowView && ((percentage <= -1 && self.isSlideLeft) || (percentage >= 1 && !self.isSlideLeft))) {
            [self successChange];
        } else {
            [self removeChange];
        }
        if (self.callback) {
            self.callback();
            self.callback = nil;
        }
        self.isSlide = NO;
    }
}

- (void)onTapGesture:(UITapGestureRecognizer *)tapGesture {
    if (_delegate && [_delegate respondsToSelector:@selector(onClickCard:)]) {
        [_delegate onClickCard:self];
    }
}
#pragma mark - logic
- (void)onViewShow:(CGFloat)percentage {
    if (self.isSlideLeft ^ (percentage < 0)) {
        return;
    }
    [self.showViewList enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0 && self.isSlideLeft) {
            return;
        }
        UIView *view = obj;
        CGFloat alpha = 1-(idx * toleranceAlpha + percentage*toleranceAlpha);
        CGFloat scale = 1-(idx*toleranceScale + percentage*toleranceScale);
        CGFloat traslation = idx*toleranceTraslation + percentage*toleranceTraslation;
        view.alpha = alpha;
        view.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeTranslation(0, traslation));
    }];
}

- (void)removeChange {
    if (self.willShowView) {
        UIView *view = self.willShowView;
        self.willShowView = nil;
        if (self.isSlideLeft) {
            [view removeFromSuperview];
            if (![self.cacheViewList containsObject:view]) {
                [self.cacheViewList addObject:view];
            }
        } else {
            [UIView animateWithDuration:0.3 animations:^{
                view.transform = CGAffineTransformMakeTranslation(-([UIScreen mainScreen].bounds.size.width - self.cardSize.width)/2-view.frame.size.width, 0);
            } completion:^(BOOL finished) {
                if (!view) {
                    return ;
                }
                [view removeFromSuperview];
                if (![self.cacheViewList containsObject:view]) {
                    [self.cacheViewList addObject:view];
                }
            }];
        }
    }
    [self viewChangeAnimation];
}

- (void)successChange {
    UIView *view;
    if (self.isSlideLeft) {
        view = [self.showViewList objectAtIndex:0];
        [UIView animateWithDuration:0.3 animations:^{
            if (view.transform.tx < 0) {
                view.transform = CGAffineTransformMakeTranslation(-view.frame.size.width - 50,view.transform.ty);
            } else {
                view.transform = CGAffineTransformMakeTranslation(view.frame.size.width + 50,view.transform.ty);
            }
        } completion:^(BOOL finished) {
            //异步操作，由于有重用机制可能导致下次滑动时willShowView指针与view对象相同，而使得willShowView无surperView.则应在做完动画后再放入复用池中
            if (!view) {
                return ;
            }
            [view removeFromSuperview];
            if (![self.cacheViewList containsObject:view]) {
                [self.cacheViewList addObject:view];
            }
        }];
    } else {
        view = self.showViewList.lastObject;
        if (view) {
            [view removeFromSuperview];
            if (![self.cacheViewList containsObject:view]) {
                [self.cacheViewList addObject:view];
            }
        }
    }

    [self.showViewList removeObject:view];
    if (self.isSlideLeft) {
        if (self.willShowView) {
            [self.showViewList addObject:self.willShowView];
            self.currentIndex++;
        }
    } else {
        if (self.willShowView) {
            [self.showViewList insertObject:self.willShowView atIndex:0];
            self.currentIndex--;
        }
    }
    if ((self.currentIndex + self.viewCount)%self.allCardCount == 0) {
        if (_delegate && [_delegate respondsToSelector:@selector(willSlideToEnd:)]) {
            [_delegate willSlideToEnd:self];
        }
    }
    [self viewChangeAnimation];
}

- (void)viewChangeAnimation {
    [self.showViewList enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            [obj addGestureRecognizer:self.tapGesture];
        }
        CGFloat alpha = 1-idx*toleranceAlpha;
        CGFloat scale = 1-idx*toleranceScale;
        CGFloat traslation = idx*toleranceTraslation;
        [UIView animateWithDuration:0.3 animations:^{
            obj.alpha = alpha;
            obj.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeTranslation(0, traslation));
        }];
    }];
}

- (UIView *)getNewViewAtIndex:(NSInteger)index {
    if (self.allCardCount == 0) {
        return nil;
    }
    index %= self.allCardCount;
    if (index < 0) {
        index += self.allCardCount;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(slideCardView:viewForIndex:)]) {
        UIView *view = [_delegate slideCardView:self viewForIndex:index];
        view.frame = CGRectMake(0, 0, self.cardSize.width, self.cardSize.height);
        view.center = self.cardCenter;
        view.alpha = 1;
        return view;
    }
    return nil;
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    currentIndex %= self.allCardCount;
    if (currentIndex < 0) {
        currentIndex += self.allCardCount;
    }
    _currentIndex = currentIndex;
}

- (NSMutableArray<UIView *> *)cacheViewList {
    if (!_cacheViewList) {
        _cacheViewList = [[NSMutableArray alloc] init];
    }
    return _cacheViewList;
}

- (NSMutableArray<UIView *> *)showViewList {
    if (!_showViewList) {
        _showViewList = [[NSMutableArray alloc] init];
    }
    return _showViewList;
}

- (void)setViewCount:(NSInteger)viewCount {
    _viewCount = viewCount;
    _cacheCount = viewCount;
}
@end
