/*
=================================================
CEDocument+ScriptingSupport
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.03.12
 
-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

#import "CEDocument+ScriptingSupport.h"
#import "CEUtilities.h"


@implementation CEDocument (ScriptingSupport)

#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 生成した textStorage のデリゲートであることをやめる
- (void)cleanUpTextStorage:(NSTextStorage *)textStorage
// ------------------------------------------------------
{
    [textStorage setDelegate:nil];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSTextStorage)
//  <== NSTextStorage
//=======================================================

// ------------------------------------------------------
/// AppleScriptの返り値としてのtextStorageが更新された
- (void)textStorageDidProcessEditing:(NSNotification *)notification
// ------------------------------------------------------
{
    NSTextStorage *storage = (NSTextStorage *)[notification object];

    [[[self editorView] textView] replaceAllStringTo:[storage string]];
    [self cleanUpTextStorage:storage];
}



#pragma mark AppleScript Accessores

//=======================================================
// AppleScript accessor
//
//=======================================================

// ------------------------------------------------------
/// ドキュメントの文字列を返す(text型)
- (NSTextStorage *)textStorage
// ------------------------------------------------------
{
    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:[[self editorView] stringForSave]];

    [storage setDelegate:self];
    // 0.5秒後にデリゲートをやめる（放置するとクラッシュの原因になる）
    [self performSelector:@selector(cleanUpTextStorage:) withObject:storage afterDelay:0.5];

    return storage;
}


// ------------------------------------------------------
/// ドキュメントの文字列をセット（全置換）
- (void)setTextStorage:(id)object;
// ------------------------------------------------------
{
    if ([object isKindOfClass:[NSTextStorage class]]) {
        [[[self editorView] textView] replaceAllStringTo:[object string]];
    }
}


// ------------------------------------------------------
/// ドキュメントの文字列を返す(text型)
- (NSTextStorage *)contents
// ------------------------------------------------------
{
    return [self textStorage];
}


// ------------------------------------------------------
/// ドキュメントの文字列をセット（全置換）
- (void)setContents:(id)object
// ------------------------------------------------------
{
    [self setTextStorage:object];
}


// ------------------------------------------------------
/// ドキュメントの文字数を返す(integer型)
- (NSNumber *)length
// ------------------------------------------------------
{
    return @([[[self editorView] stringForSave] length]);
}


// ------------------------------------------------------
/// 改行コードを返す(enum型)
- (CELineEnding)lineEnding
// ------------------------------------------------------
{
    switch ([[self editorView] lineEndingCharacter]) {
        case 1:
            return CELineEndingCR;
            break;
        case 2:
            return CELineEndingCRLF;
            break;
        default:
            return CELineEndingLF;
            break;
    }
}


// ------------------------------------------------------
/// 改行コードをセット
- (void)setLineEnding:(CELineEnding)lineEnding
// ------------------------------------------------------
{
    NSInteger code;

    switch (lineEnding) {
        case CELineEndingCR:
            code = 1;
            break;
        case CELineEndingCRLF:
            code = 2;
            break;
        case CELineEndingLF:
            code = 0;
            break;
    }
    [self doSetNewLineEndingCharacterCode:code];
}


// ------------------------------------------------------
/// エンコーディング名を返す(Unicode text型)
- (NSString *)encoding
// ------------------------------------------------------
{
    return [NSString localizedNameOfStringEncoding:[self encodingCode]];
}


// ------------------------------------------------------
/// エンコーディング名の IANA Charset 名を返す(Unicode text型)
- (NSString *)IANACharSetName
// ------------------------------------------------------
{
    NSString *name = [self currentIANACharSetName];

    // 得られなければ空文字を返す
    return name ? : @"";
}


// ------------------------------------------------------
/// カラーリングスタイル名を返す(Unicode text型)
- (NSString *)coloringStyle
// ------------------------------------------------------
{
    return [[self editorView] syntaxStyleNameToColoring];
}


// ------------------------------------------------------
/// カラーリングスタイル名をセット
- (void)setColoringStyle:(NSString *)styleName
// ------------------------------------------------------
{
    [self doSetSyntaxStyle:styleName];
}


// ------------------------------------------------------
/// selection-object を返す
- (CETextSelection *)selectionObject
// ------------------------------------------------------
{
    return [self selection];
}


// ------------------------------------------------------
/// 選択範囲へテキストを設定
- (void)setSelectionObject:(id)object
// ------------------------------------------------------
{
    if ([object isKindOfClass:[NSString class]]) {
        [[self selection] setContents:object];
    }
}


// ------------------------------------------------------
/// ワードラップの状態を返す
- (NSNumber *)wrapLines
// ------------------------------------------------------
{
    return @([[self editorView] wrapLines]);
}


// ------------------------------------------------------
/// ワードラップを切り替える
- (void)setWrapLines:(NSNumber *)wrapLines
// ------------------------------------------------------
{
    [[self editorView] setWrapLines:[wrapLines boolValue]];
}


// ------------------------------------------------------
/// 行間値を返す
- (NSNumber *)lineSpacing
// ------------------------------------------------------
{
    return @([[[self editorView] textView] lineSpacing]);
}


// ------------------------------------------------------
/// 行間値をセット
- (void)setLineSpacing:(NSNumber *)lineSpacing
// ------------------------------------------------------
{
    [[[self editorView] textView] setLineSpacing:(CGFloat)[lineSpacing doubleValue]];
}


#pragma mark AppleScript Handlers

//=======================================================
// AppleScript handler
//
//=======================================================

// ------------------------------------------------------
/// エンコーディングを変更し、テキストをコンバートする
- (NSNumber *)handleConvert:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    NSString *encodingName = arguments[@"newEncoding"];
    NSStringEncoding encoding = [CEUtilities encodingFromName:encodingName];
    BOOL success = NO;

    if (encoding == NSNotFound) {
        success = NO;
    } else if (encoding == [self encodingCode]) {
        success = YES;
    } else {
        NSString *actionName = @"TEST";
        BOOL lossy = NO;

        lossy = [arguments[@"Lossy"] boolValue];
        success = [self doSetEncoding:encoding updateDocument:YES askLossy:NO lossy:lossy asActionName:actionName];
    }

    return @(success);
}


// ------------------------------------------------------
/// エンコーディングを変更し、テキストを再解釈する
- (NSNumber *)handleReinterpret:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    NSString *encodingName = arguments[@"newEncoding"];
    NSStringEncoding encoding = [CEUtilities encodingFromName:encodingName];
    BOOL success = NO;

    if ((encoding == NSNotFound) || ![self fileURL]) {
        success = NO;
    } else if (encoding == [self encodingCode]) {
        success = YES;
    } else if ([self stringFromData:[NSData dataWithContentsOfURL:[self fileURL]] encoding:encoding xattr:NO]) {
        [self setStringToEditorView];
        // ダーティーフラグをクリア
        [self updateChangeCount:NSChangeCleared];
        // ツールバーアイテムの選択状態をセット
        [[[self windowController] toolbarController] setSelectEncoding:[self encodingCode]];
        success = YES;
    }

    return @(success);
}


// ------------------------------------------------------
/// 検索
- (NSNumber *)handleFind:(NSScriptCommand *)inCommand
// ------------------------------------------------------
{
    NSDictionary *arguments = [inCommand evaluatedArguments];
    NSString *searchStr = arguments[@"targetString"];
    if ([searchStr length] == 0) { return @NO; }
    BOOL isRegex = [arguments[@"regularExpression"] boolValue];
    BOOL ignoresCase = [arguments[@"ignoreCase"] boolValue];
    BOOL isBackwards = [arguments[@"backwardsSearch"] boolValue];
    BOOL isWrapSearch = [arguments[@"wrapSearch"] boolValue];
    NSString *wholeStr = [[self editorView] stringForSave];
    NSInteger wholeLength = [wholeStr length];
    if (wholeLength == 0) { return @NO; }
    NSRange selectionRange = [[self editorView] selectedRange];
    NSRange targetRange;

    if (isBackwards) {
        targetRange = NSMakeRange(0, selectionRange.location);
    } else {
        targetRange = NSMakeRange(NSMaxRange(selectionRange),
                                  wholeLength - NSMaxRange(selectionRange));
    }
    NSUInteger mask = 0;
    if (ignoresCase) {
        mask |= isRegex ? OgreIgnoreCaseOption : NSCaseInsensitiveSearch;
    }
    if (isBackwards) {
        mask |= NSBackwardsSearch;
    }

    BOOL success = [self doFind:searchStr range:targetRange option:mask withRegularExpression:isRegex];
    if (!success && isWrapSearch) {
        targetRange = NSMakeRange(0, wholeLength);
        success = [self doFind:searchStr range:targetRange option:mask withRegularExpression:isRegex];
    }
    
    return @(success);
}


// ------------------------------------------------------
/// 置換
- (NSNumber *)handleReplace:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    NSString *searchStr = arguments[@"targetString"];
    if ([searchStr length] == 0) { return @NO; }
    BOOL isRegex = [arguments[@"regularExpression"] boolValue];
    BOOL ignoresCase = [arguments[@"ignoreCase"] boolValue];
    BOOL isAll = [arguments[@"all"] boolValue];
    BOOL isBackwards = [arguments[@"backwardsSearch"] boolValue];
    BOOL isWrapSearch = [arguments[@"wrapSearch"] boolValue];
    NSString *wholeStr = [[self editorView] stringForSave];
    NSInteger wholeLength = [wholeStr length];
    if (wholeLength == 0) { return @NO; }
    NSString *newString = arguments[@"newString"];
    if ([searchStr isEqualToString:newString]) { return @NO; }
    if (!newString) { newString = @""; }
    NSRange selectionRange, targetRange;

    if (isAll) {
        targetRange = NSMakeRange(0, wholeLength);
    } else {
        selectionRange = [[self editorView] selectedRange];
        if (isBackwards) {
            targetRange = NSMakeRange(0, selectionRange.location);
        } else {
            targetRange = NSMakeRange(NSMaxRange(selectionRange),
                                      wholeLength - NSMaxRange(selectionRange));
        }
    }
    NSUInteger mask = 0;
    if (ignoresCase) {
        mask |= (isRegex) ? OgreIgnoreCaseOption : NSCaseInsensitiveSearch;
    }
    if (isBackwards) {
        mask |= NSBackwardsSearch;
    }

    BOOL success = NO;
    NSInteger result = 0;
    if (isAll) {
        NSMutableString *tmpStr = [wholeStr mutableCopy]; // ===== copy
        if (isRegex) {
            result = [tmpStr replaceOccurrencesOfRegularExpressionString:searchStr
                                                              withString:newString options:mask range:targetRange];
        } else {
            result = [tmpStr replaceOccurrencesOfString:searchStr
                                             withString:newString options:mask range:targetRange];
        }
        if (result > 0) {
            [[[self editorView] textView] replaceAllStringTo:tmpStr];
            [[[self editorView] textView] setSelectedRange:NSMakeRange(0,0)];
        }

    } else {
        success = [self doFind:searchStr range:targetRange option:mask withRegularExpression:isRegex];
        if (!success && isWrapSearch) {
            targetRange = NSMakeRange(0, wholeLength);
            success = [self doFind:searchStr range:targetRange option:mask withRegularExpression:isRegex];
        }
        if (success) {
            [[self selection] setContents:newString]; // （CETextSelection の setContents: の引数は NSString も可）
            result = 1;
        }
    }

    return @(result);
}


// ------------------------------------------------------
/// スクロール実行
- (void)handleScroll:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [self scrollToCenteringSelection];
}


// ------------------------------------------------------
/// 指定された範囲の文字列を返す
- (NSString *)handleString:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    NSArray *rangeArray = arguments[@"range"];
    NSInteger location, length;
    NSRange range;

    if ([rangeArray count] == 0) { return [NSString string]; }
    location = [rangeArray[0] integerValue];
    length = ([rangeArray count] > 1) ? [rangeArray[1] integerValue] : 1;
    range = [self rangeInTextViewWithLocation:location length:length];

    if (NSEqualRanges(NSMakeRange(0, 0), range)) {
        return @"";
    }
    return [[[[self editorView] textView] string] substringWithRange:range];
}



#pragma mark Private Method

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// 文字列を検索し、見つかったら選択して結果を返す
- (BOOL)doFind:(NSString *)searchString range:(NSRange)range
            option:(unsigned)option withRegularExpression:(BOOL)isRegex
// ------------------------------------------------------
{
    NSString *wholeStr = [[self editorView] string];
    NSRange searchedRange;

    if (isRegex) {
        searchedRange = [wholeStr rangeOfRegularExpressionString:searchString options:option range:range];
    } else {
        searchedRange = [wholeStr rangeOfString:searchString options:option range:range];
    }
    if (searchedRange.location != NSNotFound) {
        [[self editorView] setSelectedRange:searchedRange];
        return YES;
    }
    return NO;
}

@end
