//
//  TLMMirrorCell.m
//  TeX Live Manager
//
//  Created by Adam R. Maxwell on 11/20/10.
/*
 This software is Copyright (c) 2010-2011
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "TLMMirrorCell.h"

@implementation TLMMirrorCell

static NSMutableDictionary *_iconsByURLScheme = nil;

+ (void)initialize
{
    if (nil == _iconsByURLScheme)
        _iconsByURLScheme = [NSMutableDictionary new];
}

@synthesize icon = _icon;

- (id)initTextCell:(NSString *)aString
{
    self = [super initTextCell:aString];
    if (self) {
        [self setScrollable:YES];
        [self setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    self = [super copyWithZone:zone];
    self->_icon = [self->_icon retain];
    return self;
}

- (void)dealloc
{
    [_icon release];
    [super dealloc];
}

- (NSImage *)_iconForURL:(NSURL *)aURL
{
    NSString *scheme = [aURL scheme];
    NSImage *icon = [_iconsByURLScheme objectForKey:scheme];
    if (nil == icon) {
        
        OSType iconType = kInternetLocationGenericIcon;
        if ([scheme hasPrefix:@"http"])
            iconType = kInternetLocationHTTPIcon;
        else if ([scheme isEqualToString:@"ftp"])
            iconType = kInternetLocationFTPIcon;
        else if ([scheme isEqualToString:@"file"])
            iconType = kInternetLocationFileIcon;
        else if ([scheme isEqualToString:@"afp"])
            iconType = kInternetLocationAppleShareIcon;
        
        IconRef iconRef;
        if (noErr == GetIconRef(kOnSystemDisk, kSystemIconsCreator, iconType, &iconRef)) {
            icon = [[[NSImage alloc] initWithIconRef:iconRef] autorelease];
            ReleaseIconRef(iconRef);
        }

        [_iconsByURLScheme setObject:icon forKey:scheme];
    }
    return icon;
}

- (void)setObjectValue:(id <NSCopying>)obj
{
    NSImage *icon = [(id)obj respondsToSelector:@selector(scheme)] ? [self _iconForURL:(NSURL *)obj] : nil;
    [self setIcon:icon];
    [super setObjectValue:obj];
}

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
    NSRect drawingRect = [super drawingRectForBounds:theRect];
    NSSize cellSize = [self cellSizeForBounds:theRect];
        
    CGFloat offset = NSHeight(drawingRect) - cellSize.height;      
    if (offset > 0.5) {
        drawingRect.size.height -= offset;
        drawingRect.origin.y += (offset / 2);
    }
    
    return drawingRect;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    
    NSRect iconRect = cellFrame;
    iconRect.size.width = NSHeight(cellFrame);
    if ([controlView isFlipped] && [self icon]) {
        CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
        CGContextSaveGState(ctxt);
        CGContextSetInterpolationQuality(ctxt, kCGInterpolationHigh);
        CGContextSetShouldAntialias(ctxt, true);
        CGContextTranslateCTM(ctxt, 0, NSMaxY(iconRect));
        CGContextScaleCTM(ctxt, 1, -1);
        iconRect.origin.y = 0;
        [[self icon] drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        CGContextRestoreGState(ctxt);
    }
    
    cellFrame.origin.x = NSMaxX(iconRect);
    cellFrame.size.width -= NSWidth(iconRect);
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end