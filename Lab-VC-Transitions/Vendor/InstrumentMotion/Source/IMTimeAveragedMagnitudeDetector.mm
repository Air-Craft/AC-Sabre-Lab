/** 
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 20/11/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{ 
 */

#import "IMTimeAveragedMagnitudeDetector.h"
#import "IMDefs.h"
#import "RunningAverageAggregator.h"
#import "IMFunctions.h"
#import "InstrumentMotionDebug.h"

#import <tgmath.h>
#import <unordered_map>
#import <memory>

typedef std::pair<IMAxis, IMMotionType> _IMAxisMotionTypePair;
typedef InstrumentMotion::RunningAverageAggregator<IMMotionUnit> _IMAggregator;
typedef std::shared_ptr< _IMAggregator > _IMAggregatorPtr;

typedef struct {
    std::size_t operator() (const _IMAxisMotionTypePair& pair) const {
        return pair.first << 4 | pair.second;
    }
} _IMAxisMotionTypePairHash;



@implementation IMTimeAveragedMagnitudeDetector
{
    NSTimeInterval _sampleRate;
    
    std::unordered_map< _IMAxisMotionTypePair, NSTimeInterval, _IMAxisMotionTypePairHash> _axisTimeWindowMap;
    
    std::unordered_map<_IMAxisMotionTypePair, _IMAggregatorPtr, _IMAxisMotionTypePairHash> _aggregators;
    
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////
#pragma mark - MotionObserverProtocol Fulfillment
/////////////////////////////////////////////////////////////////////////

- (void)handleMotionObserverAddedWithSampleRate:(NSTimeInterval)aSampleRate
{
    _sampleRate = aSampleRate;
    
    // Initialise the aggregators if not already done so
    for (const auto& k : _axisTimeWindowMap) {
        NSTimeInterval timeWindow = k.second;
        NSUInteger poolSize = aSampleRate * timeWindow;
        _IMAggregatorPtr agg(new _IMAggregator(poolSize));
        _aggregators[k.first] = agg;
    }
}

/// Clear out the aggregators on removal as they may be readded with another sample rate
- (void)handleMotionObserverRemoved
{
    _aggregators.clear();
}



/////////////////////////////////////////////////////////////////////////

- (void)handleMotionUpdateForData:(IMMotionSampleSet)current previousData:(IMMotionSampleSet)previous
{
    for(auto k : _aggregators) {
        IMAxis axisBitmask = k.first.first;
        IMMotionType motionType = k.first.second;
        
        _IMAggregatorPtr aggregator = k.second;
        
        @synchronized(self) {
            aggregator->add(IM_GetMotionMagnitudeOfAxesOnSampleSet(current, axisBitmask, motionType));
        }
    }
    
    // Update any observers
    if (_onUpdateBlock) {
        if (_notifyOnMainThread) {
            dispatch_async(dispatch_get_main_queue(), ^{ _onUpdateBlock(self); });
        } else {
            _onUpdateBlock(self);
        }
    }
}



/////////////////////////////////////////////////////////////////////////
#pragma mark - Public API
/////////////////////////////////////////////////////////////////////////

- (void)setDetectionForAxis:(IMAxis)anAxisBitmask motionType:(IMMotionType)aMotionType timeWindow:(NSTimeInterval)theTimeWindow
{
    _IMAxisMotionTypePair key = _IMAxisMotionTypePair(anAxisBitmask, aMotionType);
    
    // Add to the time map
    _axisTimeWindowMap[key] = theTimeWindow;
    
    // If _sampleRate is set then also alloc the aggregator
    // This should safely replace an aggregators existing for that axis
    if (_sampleRate) {
        NSUInteger poolSize = round(theTimeWindow * _sampleRate);
        _IMAggregatorPtr agg(new _IMAggregator(poolSize));
        @synchronized(self) {
            _aggregators[key] = agg;
        }
    }
}

/////////////////////////////////////////////////////////////////////////

- (void)removeDetectionForAxis:(IMAxis)anAxisBitmask motionType:(IMMotionType)aMotionType
{
    @synchronized(self) {
        _IMAxisMotionTypePair key = _IMAxisMotionTypePair(anAxisBitmask, aMotionType);
        if (_aggregators.find(key) != _aggregators.end())
            _aggregators.erase(key);
    }
}

/////////////////////////////////////////////////////////////////////////


- (IMMotionUnit)valueForDetectionAxis:(IMAxis)anAxisBitmask motionType:(IMMotionType)aMotionType
{
    _IMAxisMotionTypePair key = _IMAxisMotionTypePair(anAxisBitmask, aMotionType);
    @synchronized(self) {
        if (_aggregators.find(key) != _aggregators.end())
            return _aggregators[key]->value();
        else {
            IMLogWarn(@"Axis for bitmask %i and motion type enum %i isn't being tracked.", anAxisBitmask, aMotionType);
            return 0;
        }
    }
}

/////////////////////////////////////////////////////////////////////////

- (IMMotionUnit)normalizedValueForDetectionAxis:(IMAxis)anAxisBitmask motionType:(IMMotionType)aMotionType
{
    IMMotionUnit normed = [self valueForDetectionAxis:anAxisBitmask motionType:aMotionType] / IM_GetMaxMagnitudeForMotionOnAxes(anAxisBitmask, aMotionType);
    return IM_Clamp(normed, 0, 1);
}

////////////////////////////////////////////////////////////////////////

- (void)reset
{
    for (auto k : _aggregators) {
        k.second->reset();
    }
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Private API
/////////////////////////////////////////////////////////////////////////

@end

/// @}