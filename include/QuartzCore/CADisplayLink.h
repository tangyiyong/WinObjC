//******************************************************************************
//
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

enum CADisplayLinkRunMode
{
    CADisplayLinkSyncMode,
    CADisplayLinkTimerMode
};

@class NSRunLoopSource;

CA_EXPORT_CLASS
@interface CADisplayLink : NSObject {
    idretain _target;
    SEL _selector;
    idretaintype(NSTimer) _timer;
    bool _isPaused;
    bool _addedToUpdateList;
    idretaintype(NSRunLoopSource) _displaySyncEvent;
    int _frameInterval;

    enum CADisplayLinkRunMode _runMode;
    NSMutableDictionary * _addedRunLoops;
    double _timestamp;
}

@property(nonatomic) NSInteger frameInterval;
@property(readonly, nonatomic) CFTimeInterval timestamp;
@property(readonly, nonatomic) CFTimeInterval duration;
@property(getter=isPaused, nonatomic) BOOL paused;

+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel;

- (void)invalidate;
- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSString *)mode;
- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSString *)mode;

@end