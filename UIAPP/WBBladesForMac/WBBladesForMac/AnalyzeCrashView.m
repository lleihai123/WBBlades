//
//  AnalyzeCrashView.m
//  WBBladesForMac
//
//  Created by phs on 2019/12/20.
//  Copyright © 2019 邓竹立. All rights reserved.
//

#import "AnalyzeCrashView.h"

@interface AnalyzeCrashView()

@property (nonatomic,weak) NSTextView *ipaFileView;
@property (nonatomic,weak) NSTextView *crashStackView;
@property (nonatomic,weak) NSTextView *resultView;
@property (nonatomic,copy) NSMutableArray *crashStacks;
@end

@implementation AnalyzeCrashView

- (instancetype)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self prepareSubview];
    }
    return self;
}

- (void)prepareSubview{
    NSTextField *ipaLabel = [[NSTextField alloc]initWithFrame:NSMakeRect(25.0, 428.0, 70, 36.0)];
    [self addSubview:ipaLabel];
    ipaLabel.font = [NSFont systemFontOfSize:14.0];
    ipaLabel.stringValue = @"可执行文件路径";
    ipaLabel.textColor = [NSColor blackColor];
    ipaLabel.editable = NO;
    ipaLabel.bezelStyle = NSBezelStyleTexturedSquare;
    ipaLabel.bordered = NO;
    ipaLabel.backgroundColor = [NSColor clearColor];
    
    NSTextView *textView = [[NSTextView alloc]initWithFrame:NSMakeRect(109.0, 434.0, 559.0, 36.0)];
    [self addSubview:textView];
    textView.font = [NSFont systemFontOfSize:14.0];
    textView.textColor = [NSColor blackColor];
    textView.wantsLayer = YES;
    textView.layer.backgroundColor = [NSColor whiteColor].CGColor;
    textView.layer.borderWidth = 1.0;
    textView.layer.cornerRadius = 2.0;
    textView.layer.borderColor = [NSColor lightGrayColor].CGColor;
    _ipaFileView = textView;
    
    NSButton *ipaPreviewBtn = [[NSButton alloc]initWithFrame:NSMakeRect(693.0, 432.0, 125.0, 40.0)];
    [self addSubview:ipaPreviewBtn];
    ipaPreviewBtn.title = @"选择可执行文件";
    ipaPreviewBtn.font = [NSFont systemFontOfSize:14.0];
    ipaPreviewBtn.target = self;
    ipaPreviewBtn.action = @selector(ipaPreviewBtnClicked:);
    ipaPreviewBtn.bordered = YES;
    ipaPreviewBtn.bezelStyle = NSBezelStyleRegularSquare;
    
    NSTextField *crashOriLabel = [[NSTextField alloc]initWithFrame:NSMakeRect(25.0, 364.0, 434.0, 38.0)];
    [self addSubview:crashOriLabel];
    crashOriLabel.font = [NSFont systemFontOfSize:14.0];
    crashOriLabel.stringValue = @"需要解析的堆栈（只粘贴需要解析的堆栈）";
    crashOriLabel.textColor = [NSColor blackColor];
    crashOriLabel.editable = NO;
    crashOriLabel.bordered = NO;
    crashOriLabel.backgroundColor = [NSColor clearColor];
    
    NSButton *startBtn = [[NSButton alloc]initWithFrame:NSMakeRect(693.0, 376.0, 125.0, 40.0)];
    [self addSubview:startBtn];
    startBtn.title = @"开始解析";
    startBtn.font = [NSFont systemFontOfSize:14.0];
    startBtn.target = self;
    startBtn.action = @selector(startBtnClicked:);
    startBtn.bordered = YES;
    startBtn.bezelStyle = NSBezelStyleRegularSquare;
    
    NSScrollView *scrollView = [[NSScrollView alloc]initWithFrame:NSMakeRect(30.0, 214.0, 765.0, 148.0)];
    [self addSubview:scrollView];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setBorderType:NSLineBorder];
    scrollView.wantsLayer = YES;
    scrollView.layer.backgroundColor = [NSColor whiteColor].CGColor;
    scrollView.layer.borderWidth = 1.0;
    scrollView.layer.cornerRadius = 2.0;
    scrollView.layer.borderColor = [NSColor lightGrayColor].CGColor;
    
    NSTextView *crashTextView = [[NSTextView alloc]initWithFrame:NSMakeRect(0, 0, 765.0, 148.0)];
     scrollView.documentView = crashTextView;
    crashTextView.font = [NSFont systemFontOfSize:14.0];
    crashTextView.textColor = [NSColor blackColor];
    _crashStackView = crashTextView;
    
    NSTextField *resultLabel = [[NSTextField alloc]initWithFrame:NSMakeRect(25.0, 161.0, 434.0, 38.0)];
    [self addSubview:resultLabel];
    resultLabel.font = [NSFont systemFontOfSize:14.0];
    resultLabel.stringValue = @"解析结果";
    resultLabel.textColor = [NSColor blackColor];
    resultLabel.editable = NO;
    resultLabel.bordered = NO;
    resultLabel.backgroundColor = [NSColor clearColor];
    
    NSScrollView *scrollView2 = [[NSScrollView alloc]initWithFrame:NSMakeRect(30.0, 20.0, 765.0, 148.0)];
    [self addSubview:scrollView2];
    [scrollView2 setHasVerticalScroller:YES];
    [scrollView2 setBorderType:NSLineBorder];
    scrollView2.wantsLayer = YES;
    scrollView2.layer.backgroundColor = [NSColor whiteColor].CGColor;
    scrollView2.layer.borderWidth = 1.0;
    scrollView2.layer.cornerRadius = 2.0;
    scrollView2.layer.borderColor = [NSColor lightGrayColor].CGColor;
    
    NSTextView *resultTextView = [[NSTextView alloc]initWithFrame:NSMakeRect(0, 0, 765.0, 148.0)];
    scrollView2.documentView = resultTextView;
    resultTextView.font = [NSFont systemFontOfSize:14.0];
    resultTextView.textColor = [NSColor blackColor];
    _resultView = resultTextView;
}

- (void)ipaPreviewBtnClicked:(id)sender{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setPrompt:@"选择可执行文件"];
    openPanel.allowsMultipleSelection = NO;
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.directoryURL = nil;
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"", nil]];
    __weak __typeof(self) weakself = self;
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        
        if (returnCode == 1 && [openPanel URLs]) {
            NSMutableString *fileFolders = [NSMutableString stringWithString:@""];
            NSArray *array = [openPanel URLs];
            for (NSInteger i = 0; i < array.count; i++) {
                NSURL *url = array[i];
                NSString *urlString = [url.absoluteString substringFromIndex:7];
                NSString *string = @",";
                if (i == array.count - 1) {
                    string = @"";
                }
                [fileFolders appendFormat:@"%@%@",urlString,string];
            }
            weakself.ipaFileView.string = [fileFolders copy];
            weakself.ipaFileView.editable = NO;
        }
    }];
}

- (void)startBtnClicked:(id)sender{
    //NSString *pureStr = [_ipaFileView.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    //NSArray *paths = [pureStr componentsSeparatedByString:@".ipa"];
    
//    if (!(paths.count == 2) || (paths.count == 2 && ![paths[1]  isEqual: @""])) {
//        NSAlert *alert = [[NSAlert alloc] init];
//        [alert addButtonWithTitle:@"好的"];
//        [alert setMessageText:@"请选择或拖入一个.ipa文件"];
//        [alert beginSheetModalForWindow:self.window completionHandler:nil];
//        return;
//    }
    
//    NSString *crashInfo = [_crashStackView.string stringByReplacingOccurrencesOfString:@" " withString:@""];
//    NSArray *crashComp = [crashInfo componentsSeparatedByString:@"+"];
//    NSString *crash = _crashStackView.string;
//    NSLog(@"%@", _crashStackView.string);
    NSString *execName = [_ipaFileView.string componentsSeparatedByString:@"/"].lastObject;
    NSLog(@"%@",execName);
    NSArray *crashInfoLines = [_crashStackView.string componentsSeparatedByString:@"\n"];
    NSMutableArray *crashOffsets = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < crashInfoLines.count; i++) {
        NSString *crashLine = crashInfoLines[i];
        NSString *lineTrimmingSpace = [crashLine stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *comps = [lineTrimmingSpace componentsSeparatedByString:@"+"];
        NSString *offset = comps.lastObject;
        if(offset.longLongValue) {
            [crashOffsets addObject:[NSString stringWithString:offset]];
        }
    }
    if (crashOffsets.count > 0) {
        NSString *offsets = [crashOffsets componentsJoinedByString:@","];
        [self analyzeCrashFromOffsets:offsets];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"好的"];
        [alert setMessageText:@"请粘贴崩溃堆栈"];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        return;
    }
}

-(void)analyzeCrashFromOffsets:(NSString*)offsets {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WBBlades" ofType:@""];
    NSTask *bladesTask = [[NSTask alloc] init];
    [bladesTask setLaunchPath:path];
    [bladesTask setArguments:[NSArray arrayWithObjects:@"3", [NSString stringWithString:_ipaFileView.string], [NSString stringWithString:offsets], nil]];
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [bladesTask setStandardOutput:pipe];
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    [bladesTask launch];
    NSData *data;
    data = [file readDataToEndOfFile];
    //NSArray *arr = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSString class] fromData:data error:nil];
    //NSLog(@"results array is %@",arr);
    NSString *resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //NSLog(@"%@", resultStr);
    //NSDictionary *resultsDic = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSDictionary class] fromData:data error:nil];
    NSDictionary *resultsDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    [self outputResults:resultStr];
    [bladesTask waitUntilExit];
    
}

- (void)outputResults:(NSString*)resultStr {
    _resultView.string = [resultStr copy];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
