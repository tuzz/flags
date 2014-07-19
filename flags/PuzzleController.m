//
//  PuzzleController.m
//  flags
//
//  Created by Edwin Bos on 24/05/2014.
//  Copyright (c) 2014 chris. All rights reserved.
//

#import "PuzzleController.h"
#import "LayeredView.h"
#import "PaintPotView.h"
#import "PatternView.h"
#import "Quiz.h"
#import "ResultsController.h"
#import "FeedbackController.h"
#import "Flag.h"

@interface PuzzleController () <PaintPotViewDelegate, PatternViewDelegate, LayeredViewDelegate>

@property (nonatomic, weak) IBOutlet LayeredView *layeredView;
@property (nonatomic, strong) Quiz *quiz;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) NSArray *paintPots;
@property (nonatomic, strong) NSArray *patterns;
@property (nonatomic, weak) IBOutlet UIButton *submitButton;
@property (nonatomic, strong) DifficultyScaler *difficultyScaler;
@property (nonatomic, strong) Flag *currentPatternFlag;

@end

@implementation PuzzleController

@synthesize difficulty=_difficulty;

- (void)viewDidLoad
{
    NSString *previousTitle = [self previousTitle];
    
    self.difficulty = [previousTitle isEqualToString:@"colours"] ? @"easy" : @"hard";
    self.navigationItem.title = previousTitle;
    
    self.layeredView.backgroundColor = [UIColor clearColor];
    [self.layeredView setDelegate:self];
    
    NSString *difficultyKey = [NSString stringWithFormat:@"puzzle-%@", self.difficulty];
    self.difficultyScaler = [[DifficultyScaler alloc] initWithDifficultyKey:difficultyKey];
    
    NSArray *flags = [self.difficultyScaler scale:[Flag all]];
    self.quiz = [[Quiz alloc] initWithArray:flags andRounds:3];
    
    UIFont *titleFont = [UIFont fontWithName:@"BPreplay-Bold" size:30];
    [self.nameLabel setFont:titleFont];
    
    [self nextFlag];
    
    [super viewDidLoad];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (![self.difficulty isEqualToString:@"easy"]) {
        return;
    }
    
    NSInteger y = 266 + 14; // 14 points padding below layered view.
    
    for (PaintPotView *pot in self.paintPots) {
        CGRect f = pot.frame;
        pot.frame = CGRectMake(f.origin.x, y, f.size.width, 41);
    }

    y += 41 + 16; // 16 points padding below paint pots.
    
    CGRect f = self.submitButton.frame;
    self.submitButton.frame = CGRectMake(f.origin.x, y, f.size.width, f.size.height);
}

- (void)nextFlag
{
    [self.layeredView setPaintColor:nil];
    
    Flag *flag = [self.quiz currentElement];
    
    if (flag) {
        [self.difficultyScaler increaseDifficulty];
        [self setSubmitButtonState:NO];
        [self.nameLabel setText:[flag name]];
        [self setupChoices:flag];
    }
    else {
        [self showResults];
    }
}

- (IBAction)submit
{
    BOOL correct = [self isCorrect];
    
    if (correct) {
        [self.quiz correct];
    }
    else {
        [self.quiz incorrect];
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    FeedbackController *feedback = [storyboard instantiateViewControllerWithIdentifier:@"FeedbackController"];
    feedback.correct = correct;
    
    [self.navigationController pushViewController:feedback animated:NO];
}

- (void)showResults
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ResultsController *results = [storyboard instantiateViewControllerWithIdentifier:@"ResultsController"];
    results.quiz = self.quiz;
    results.difficulty = self.difficulty;
    
    [self.navigationController pushViewController:results animated:YES];
}

- (NSArray *)viewsForClass:(id)class
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[class class]]) {
            [array addObject:subview];
        }
    }
    
    return [NSArray arrayWithArray:array];
}

- (void)touchedLayeredView:(LayeredView *)layeredView
{
    [self setSubmitButtonState:YES];
}

- (void)setSubmitButtonState:(BOOL)state
{
    NSString *difficulty = [self.difficulty isEqualToString:@"easy"] ? @"Easy" : @"Hard";
    NSString *active = state ? @"Enabled" : @"Disabled";
    NSString *imageName = [NSString stringWithFormat:@"Done-Button-%@-%@", difficulty, active];
    
    [self.submitButton setUserInteractionEnabled:state];
    [self.submitButton setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (NSString *)previousTitle
{
    NSInteger previousIndex = [self.navigationController.viewControllers count] - 2;
    UIViewController *previousController = [self.navigationController.viewControllers objectAtIndex:previousIndex];
    return previousController.navigationItem.title;
}

- (BOOL)isCorrect
{
    if ([self.difficulty isEqualToString:@"easy"]) {
        return [self.layeredView isCorrect];
    }
    else {
        return [self.layeredView isCorrect] && [self.currentPatternFlag isEqualTo:self.quiz.currentElement];
    }
}

# pragma mark choice set up

- (void)setupChoices:(Flag *)flag
{
    [self setupPaintPots:flag];
    [self setupPatterns:flag];
    
    if ([self.difficulty isEqualToString:@"easy"]) {
        [self.layeredView setFlag:flag];
        [self touchFirstPaintPot];
        [self removePatterns];
    }
    else {
        [self.layeredView setBlank];
        [self hidePaintPots];
        [self hideSubmitButton];
    }
}

- (void)setupPaintPots:(Flag *)flag
{
    self.paintPots = [self viewsForClass:[PaintPotView class]];
    NSArray *colors = [flag shuffledColors];
    
//    if ([self.paintPots count] != [colors count]) {
//        [NSException raise:@"Counts do not match" format:@"For flag %@", [flag name]];
//    }
    
    for (NSInteger i = 0; i < [self.paintPots count]; i++) {
        PaintPotView *pot = [self.paintPots objectAtIndex:i];
        
        if (i < [colors count]) {
            UIColor *color = [colors objectAtIndex:i];
        
            [pot setDelegate:self];
            [pot setColor:color];
        }
        else {
            NSLog(@"Missing incorrect color - skipping");
        }
    }
}

- (void)setupPatterns:(Flag *)flag
{
    self.patterns = [self viewsForClass:[PatternView class]];
    NSArray *patternFlags = [self.quiz.currentElement patternFlags];
    
    for (NSInteger i = 0; i < [self.patterns count]; i++) {
        PatternView *pattern = [self.patterns objectAtIndex:i];
        Flag *patternFlag = [patternFlags objectAtIndex:i];
        
        [pattern setFlag:patternFlag];
        [pattern setFlagImage];
        [pattern setDelegate:self];
    }
}

- (void)touchFirstPaintPot
{
    [self touchedPaintPot:[self.paintPots firstObject]];
}

- (void)removePatterns
{
    for (PatternView *patternView in self.patterns) {
        [patternView removeFromSuperview];
    }
}

- (void)hidePaintPots
{
    for (PaintPotView *paintPot in self.paintPots) {
        paintPot.hidden = YES;
    }
}

- (void)showPaintPots
{
    for (PaintPotView *paintPot in self.paintPots) {
        paintPot.hidden = NO;
    }
}

- (void)hideSubmitButton
{
    self.submitButton.hidden = YES;
}

- (void)showSubmitButton
{
    self.submitButton.hidden = NO;
}

- (void)touchedPaintPot:(PaintPotView *)paintPot
{
    [self.layeredView setPaintColor:paintPot.backgroundColor];
    
    for (PaintPotView *view in self.paintPots) {
        [view setHighlighted:NO];
    }
    [paintPot setHighlighted:YES];
}

- (void)touchedPattern:(PatternView *)pattern
{
    self.currentPatternFlag = pattern.flag;
    [self.layeredView setFlag:pattern.flag];
    
    [self showPaintPots];
    [self showSubmitButton];
    [self touchFirstPaintPot];
}

@end
