/**
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 14/08/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{
 */
/// \file RunningAverageAggregator

#ifndef __InstrumentMotion__TimeWindowAverageAggregator__
#define __InstrumentMotion__TimeWindowAverageAggregator__

#include <queue>
#include <list>

namespace InstrumentMotion {
    
    /////////////////////////////////////////////////////////////////////////
#pragma mark - Declaration
    /////////////////////////////////////////////////////////////////////////
    
    
    template <typename SampleType=double>
    class RunningAverageAggregator
    {
    public:
        RunningAverageAggregator(uint32_t aPoolSize) :
        _poolSize(0),
        _sum(0),
        _samples(std::queue<SampleType>())
        {
            adjustPoolSizeTo(aPoolSize);
        }
        
        
    public:
        /// Set the pool size to a new value.  You need to call reset to update the actual queue data and aggregate value
        void poolSize(uint32_t newSize);
        uint32_t poolSize();
        
        /// Set the pool size to a new value adjusting the queue and preserving existing data
        void adjustPoolSizeTo(uint32_t newSize);
        void add(SampleType value);   // override
        void reset();
        
        /** The current average of the last N (<= poolSize) samples added.  If none, then it returns 0. If only 1 then the average will be the sample's value. */
        SampleType value();
        
    private:
        std::queue<SampleType> _samples;
        SampleType _sum;
        uint32_t _poolSize;
    };
    
    
    
/////////////////////////////////////////////////////////////////////////
#pragma mark - Definitions
/////////////////////////////////////////////////////////////////////////
    template <typename SampleType>
    void RunningAverageAggregator<SampleType>::poolSize(uint32_t newSize)
    {
        _poolSize = newSize;
    }
    
    template <typename SampleType>
    uint32_t RunningAverageAggregator<SampleType>::poolSize()
    {
        return _poolSize;
    }
    
    template <typename SampleType>
    void RunningAverageAggregator<SampleType>::adjustPoolSizeTo(uint32_t newSize)
    {
        // Push to fill with 0's or pop to remove some samples.
        // Be sure to update the sum too!
        int diff = newSize - _poolSize;
        if (diff > 0) {
            // Init queue
            for (int i=0; i<diff; i++) {
                _samples.push(0);
            }
            
        } else if (diff < 0) {
            for (int i=0; i < -diff; i++) {
                _sum -= _samples.front();
                _samples.pop();
            }
        } else {    // no change
            return;
        }
        
        _poolSize = newSize;
    }
    
    
    
    template <typename SampleType>
    void RunningAverageAggregator<SampleType>::add(SampleType value)
    {
        // Remove old and add the new
        _sum -= _samples.front();
        _samples.pop();
        _sum += value;
        _samples.push(value);
    }
    
    
    
    template <typename SampleType>
    SampleType RunningAverageAggregator<SampleType>::value()
    {
        // Report 0 if no samples
        if (!_samples.size()) return SampleType(0);
        
        return _sum / SampleType(_samples.size());
    }
    
    template <typename SampleType>
    void RunningAverageAggregator<SampleType>::reset()
    {
        // Clear out the queue and fill with zeros
        for (int i=0; i<_samples.size(); i++) {
            _samples.pop();
            _samples.push(0);
        }
        
        _sum = 0;
    }
}





#endif /* defined(__Marshmallows__TimeWindowAverageAggregator__) */

/// @}
