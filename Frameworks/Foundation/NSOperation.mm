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

#include "Starboard.h"
#include "Foundation/NSOperation.h"
#include "Foundation/NSString.h"
#include "Foundation/NSMutableArray.h"

@implementation NSOperation : NSObject
    /* annotate with type */ +(id) allocWithZone:(NSZone*)zone {
        NSOperation* ret = [super allocWithZone:zone];

        ret->priv = new NSOperationPriv();

        [ret addObserver:(id) ret forKeyPath:@"isFinished" options:0 context:nil];

        return ret;
    }

    -(NSOperationQueuePriority) queuePriority {
        return priv->priority;
    }

    /* annotate with type */ -(void) addDependency:(id)operation {
        if ( priv->dependencies == nil ) {
            priv->dependencies = [[NSMutableArray alloc] init];
        }
        [priv->dependencies addObject:operation];
    }

    /* annotate with type */ -(void) setQueuePriority:(NSOperationQueuePriority)priority {
        priv->priority = priority;
    }

    /* annotate with type */ -(id) setThreadPriority:(double)priority {
        EbrDebugLog("NSOperationQueue setThreadPriority not supported\n");
        return self;
    }

    /* annotate with type */ -(void) setCompletionBlock:(void(^)())block {
        id oldBlock = priv->completionBlock;
        priv->completionBlock = [block copy];
        [oldBlock release];
    }

    /* annotate with type */ -(void(^)()) completionBlock {
        return priv->completionBlock;
    }

    -(BOOL) isReady {
        //  Note, check dependencies when we get them
        int count = [priv->dependencies count];

        for ( int i = 0; i < count; i ++ ) {
            id op = [priv->dependencies objectAtIndex:i];

            if (![op isFinished]) return NO;
        }
        return YES;
    }

    -(BOOL) isCancelled {
        return priv->cancelled != 0;
    }

    -(BOOL) isFinished {
        return priv->finished != 0;
    }

    -(BOOL) isExecuting {
        return priv->executing != 0;
    }

    /* annotate with type */ -(void) start {
       if ( !priv->executing && !priv->finished) {
           bool execute = false;

            pthread_mutex_lock(&priv->finishLock);
            if ( !priv->cancelled ) {
                [self willChangeValueForKey:@"isExecuting"];
                priv->executing = 1;
                [self didChangeValueForKey:@"isExecuting"];
                execute = true;
            }
            pthread_mutex_unlock(&priv->finishLock);
            if ( execute ) [self main];

            if ( execute ) [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            pthread_mutex_lock(&priv->finishLock);
            priv->finished = 1;
            [self didChangeValueForKey:@"isFinished"];
            if ( execute ) {
                priv->executing = 0;
                [self didChangeValueForKey:@"isExecuting"];
            }
            pthread_mutex_unlock(&priv->finishLock);
        }
    }

    /* annotate with type */ -(void) cancel {
        if ( priv->cancelled == 0 ) {
            pthread_mutex_lock(&priv->finishLock);
            [self willChangeValueForKey:@"isCancelled"];
            priv->cancelled = 1;
            [self didChangeValueForKey:@"isCancelled"];
            pthread_mutex_unlock(&priv->finishLock);
        }
    }

    /* annotate with type */ -(void) main {
        
    }

    /* annotate with type */ -(void) waitUntilFinished {
        pthread_mutex_lock(&priv->finishLock);
        if ( ![self isFinished] ) {
            pthread_cond_wait(&priv->finishCondition, &priv->finishLock);
        }
        pthread_mutex_unlock(&priv->finishLock);
    }

    /* annotate with type */ -(id) dependencies {
        return priv->dependencies;
    }

    /* annotate with type */ -(void) observeValueForKeyPath:(id)keyPath ofObject:(id)obj change:(id)changeDictionary context:(void *)context {
        pthread_mutex_lock(&priv->finishLock);
        int finished = [self isFinished];
        if ( finished ) {
            pthread_cond_broadcast(&priv->finishCondition);
        }
        pthread_mutex_unlock(&priv->finishLock);

        // Someone might do something stupid like waitUntilFinished in the completion block,
        // which would deadlock if these weren't separated.
        if ( finished && priv->completionBlock != nil ) {
            EbrCallBlock(priv->completionBlock, "d", priv->completionBlock);
            [priv->completionBlock release];
            priv->completionBlock = nil;
        }
    }

    -(void) dealloc {
        assert(priv->completionBlock == nil);
        [self removeObserver:self forKeyPath:@"isFinished"];
        delete priv;
        [super dealloc];
    }

    
@end

