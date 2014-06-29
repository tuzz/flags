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
#import "PaletteService.h"
#import "Quiz.h"
#import "ResultsController.h"
#import "Utils.h"

@interface PuzzleController () <PaintPotViewDelegate>

@property (nonatomic, weak) IBOutlet LayeredView *layeredView;
@property (nonatomic, strong) Quiz *quiz;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *feedbackLabel;
@property (nonatomic, strong) NSArray *paintPots;

@end

@implementation PuzzleController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.layeredView.backgroundColor = [UIColor clearColor];
    self.quiz = [[Quiz alloc] initWithArray:[Utils puzzleFlags] andRounds:2];
    
    [self nextFlag:nil];
}

- (void)nextFlag:(NSTimer *)timer
{
    [self setUserInteraction:YES];
    [self.layeredView setPaintColor:nil];
    
    NSString *flagName = [self.quiz currentElement];
    
    if (flagName) {
        [self.nameLabel setText:flagName];
        [self.feedbackLabel setText:@""];
        [self.layeredView setFlag:flagName];
        [self setupPaintPots:flagName];
        [self touchFirstPaintPot];
    }
    else {
        [self showResults];
    }
}

- (IBAction)submit
{
    if ([self.layeredView isCorrect]) {
        [self.quiz correct];
        [self.feedbackLabel setText:@"correct"];
    }
    else {
        [self.quiz incorrect];
        [self.feedbackLabel setText:@"incorrect"];
    }
    
    [self setUserInteraction:NO];
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(nextFlag:) userInfo:nil repeats:NO];
}

- (void)showResults
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ResultsController *results = [storyboard instantiateViewControllerWithIdentifier:@"ResultsController"];
    results.quiz = self.quiz;
    
    [self.navigationController pushViewController:results animated:YES];
}

- (void)setupPaintPots:(NSString *)flagName
{
    self.paintPots = [self paintPotViews];
    NSArray *colors = [PaletteService shuffledColors:flagName];
    
    if ([self.paintPots count] != [colors count]) {
        [NSException raise:@"Counts do not match" format:@"For flag %@", flagName];
    }
    
    for (NSInteger i = 0; i < [self.paintPots count]; i++) {
        PaintPotView *pot = [self.paintPots objectAtIndex:i];
        UIColor *color = [colors objectAtIndex:i];
        
        [pot setDelegate:self];
        [pot setBackgroundColor:color];
    }
}

- (NSArray *)paintPotViews
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[PaintPotView class]]) {
            [array addObject:subview];
        }
    }
    
    return [NSArray arrayWithArray:array];
}

- (void)touchedPaintPot:(PaintPotView *)paintPot
{
    [self.layeredView setPaintColor:paintPot.backgroundColor];
    
    for (PaintPotView *view in self.paintPots) {
        [view setHighlighted:NO];
    }
    [paintPot setHighlighted:YES];
}

- (void)touchFirstPaintPot
{
    [self touchedPaintPot:[self.paintPots firstObject]];
}

- (void)setUserInteraction:(BOOL)state
{
    self.view.userInteractionEnabled = state;
    self.navigationController.view.userInteractionEnabled = state;
    
    for (UIView *view in self.view.subviews) {
        [view setUserInteractionEnabled:state];
    }
}

@end
