#import <tgmath.h>
#import "IMConfig.h"
#import "IMDefs.h"
#import "IMMotionDetectorProtocol.h"
#import "IMMotionAnalyzer.h"
#import "IMPluckDetectorDelegate.h"

/**
 \ingroup   InstrumentMotion
 \brief     Reads motion data and sends notifications on a virtual strings being "plucked"
 
 \section OVERVIEW OVERVIEW
 Virtual strings are situated in the centre of a "pluckzone" spread
 out evenly within designated range of the device's yaw.  The zone
 begins at a string's center and continues to plus/minus a certain 
 tolerance (tao/2) depending on the which direction the motion comes.  
 When the pluckzone center is crossed with at least one touch on the screen, and 
 then the opposite side is exited (+ tao/2 for positive yaw velocity 
 or - tao/2 for negative yaw velocity) without the touch ending   
 and the device is within the pitch angle range, a "pluck" 
 message is sent to any registered observers indicating the index (0 based) of the 
 virtual string/pluckzone which was "plucked" along with a normalised velocity
 (0 < vel <= 1) which is based on the exit velocity and the pitch angle within the 
 range (higher pitch angle = greater velocity scaling factor).  
 Lifting the finger or leaving the pitch angle range unlatches the detection mechanism.
 
 
 \section important IMPORTANT NOTES
 - This module is decoupled from note values and other musical information.
 - Pluckzones (used because "string" is an overloaded word in coding!) are 0 index
 based, eg. last zone index = count - 1
 - A delegate pattern is used for pluck observers.  This is to ensure good practice in that there is a single point for handling what to do with the plucks
 
 \section threadsafety THREAD SAFETY
 There isn't any thread safety except for "reset" (which probably should be removed).  Basically stop the control thread before changing any of the properties, call reset and then resume.  None of them need realtime control.
 
 \section detecting DETECTION ALGORITHM
 The first string is located at tolerance/2 with yawMin being the negative
 exit point.  The last string (if count > 1) is at yawMax-tolerance/2 with yawMax
 being the exit point.  The exit boundaries are open (> <) with the entry boundaries 
 treated as closed (>= <=) to allow for the edge strings to be plucked.
 ie...
 <pre>
 x.  |  .            .  |  .              .  |  .x          
 x.  |  .            .  |  .              .  |  .x
 x.  |  .            .  |  .              .  |  .x
 x.  |  .            .  |  .              .  |  .x
 x.  |  .            .  |  .              .  |  .x
 "x" => yawMin, yawMax
 "|" => virtual string, pluck zone centre
 "." => center +- tao/2, the pluck exit zone for +- yaw motion
 </pre>
 
 In other words, the string is picked up in the center and plucked when
 exited out the side moving the same direction - just like a real string.
 
 Tolerance tao is set via a zoneSensitivity property which indicates the
 fraction the zone tao is w.r.t. the full pluck axis range.  In other words for
 sensitivity constant T:
 
 \f$ \tau = \frac{1}{T}(\gamma_{max} - \gamma_{min})\f$
 
 T should generally be much higher than 1, say 25-100.
 
 There are 3 key parts to the algorithm:<br/>
 -# Detect any zones that were entered and exited since the last sample
 -# Detect any zones that were previous entered and have now been exited
 -# Detect any zone that have been entered but not yet exited and set a latch for it
    (note there can only be one of these)
 
 The first key formula is for the position, \f$\Gamma\f$, of a zone's 
 left (negative), center, and right (positive) edge given the zone index, 
 i, and count, N:
 
 \f$ \left(\begin{array}{c} \Gamma_{neg}(i) \\ \Gamma_{center}(i) \\ \Gamma_{pos}(i) \end{array}\right) = \frac{\displaystyle \gamma_{max} - \gamma_{min} - \tau}{\displaystyle (N - 1)}i + \gamma_{min} + \left(\begin{array}{c} 0 \\ {\tau/2} \\ \tau \end{array}\right) \f$
 
 One option would be to loop though the strings checking the conditions for each.  
 A more efficient way is to invert this formula and calculate an interpolated index 
 as a float for a given yaw.  For example if for yaw = 0.123, you get index = 1.45 
 that means you passed zone 1 and are midway to zone 2.  We need this value with respect
 to the negative, center and positive edges of the zone.  The inverted formula is...
 
 \f$ \begin{pmatrix} i_{neg} \\ i_{center} \\ i_{pos} \end{pmatrix}(\gamma) = 
    \frac{\displaystyle(\gamma - \gamma_{min} - \begin{pmatrix} 0 \\ \tau/2 \\ \tau \end{pmatrix})(N - 1)}{\displaystyle \gamma_{max} - \gamma_{min} - \tau}   \f$
 
 These values are calculated on the current yaw position and the one we sampled on the
 previous round.
 
 <h4>Part 1: Zones crossed entirely within the last sample</h4>
 Eg, on the prev sample, we were between zones 2 and 3 and now we are
 between zones 8 and 9 (a very fast swipe).  We want zones 3-8 to register
 plucks (but not 2 and 9).
 
 In other words we want the nearest zone center that we were moving toward but
 hadn't crossed at the previous sample - that's our starting index for plucks -
 and the nearest zone edge (pos for pos motion, neg for neg) that is now behind us 
 (wrt to velocity direction again) - thats our ending index.  Then we send signals 
 for start index through end index.  See the code for algorithmic details.  
 
 <h4>Part 2: Test for pluck on previously a latched string</h4>
 If we entered a zone on the last sample but didn't leave it, we need to check 
 whether we've left it now.  If we left it going the same direction then this is 
 a pluck.  If we turned around left it out the edge we came in, disengage the latch.
 Note, if we are still in it, the latch stays unmodified.
 
 <h4>Part 3: Test for a string to be latched</h4>
 If we are now inside a pluck zone but weren't inside the same one previously,
 we need to set the latch with the index and the IMAttitudeDirection it was entered
 in through.
 
 This is a bit tricky:  For positive motion, being in the zone means the current 
 position isn't passed the positive edge but is passed the zone center.  In this
 case the floor of the interpolated index for the positive edge will be less than 
 that for the zone center. We then combine this with a check that we were indeed to 
 the left of the center on the previous sample to confirm our latching.
 
 For example, if we are passed the zone center for zone 2, then the interpolated index
 w.r.t the center might be 2.08.  However, if we haven't passed the positive edge being
 then the interpolated index wrt this edge would be <2, perhaps 1.95.  The floor(2) > 
 floor(1.95) this we are in the zone.  If on the previous sample we were to the left
 of this zone entirely then the interpolated index wrt to the zone center would be < 2, 
 perhaps 1.56 - floor(1.56) < floor(2.08) so we have indeed entered this zone from the 
 positive direction during the most recent sample.
 
 <h3>OTHER DEVELOPER NOTES:</h3>
 - Calculated yaw velocity is prefered to raw gyro data as CMAttitude is normalised
 the world axes rather than the phones.  Ie, the yaw plane stays horizontal even
 with the device is pitched or rolled.
 
 - Note we sample out own previous yaw values as the clock we run this on may later
 be different than the one MotionAnalyzer uses.
 
 \todo Sanitize sensitivity and vel augment factor
*/
@interface IMPluckDetector : NSObject <IMMotionDetectorProtocol>



/**
 Primary init function with required parameters
 \todo  Update for new params
 \param cnt             The number of virtual pluck strings between minYw and maxYw
 \param minPA           The angle marking where the first "string's" pluck zone begins
 \param maxPA           The angle marking where the last string's pluck zone ends
 for details.
 */
- (IMPluckDetector *)initWithPluckZoneCount:(NSUInteger)cnt
                              minPluckAngle:(IMMotionUnit)minPA
                              maxPluckAngle:(IMMotionUnit)maxPA;



/////////////////////////////////////////////////////////////////////////
#pragma mark - Configuration Properties
/////////////////////////////////////////////////////////////////////////

/**
 @name Configuration properties
 Make sure your motion analzer is disengaged before updating these properties (NOT THREAD SAFE)
 @{
 */

/** Number of virtual strings (pluck zones) in the instument */
@property (nonatomic) NSUInteger zoneCount;

@property (nonatomic) IMAxis zoneLayoutAxis;   ///< Axis along which you need to move in order to pluck a virtual string (zone)
@property (nonatomic) IMMotionUnit minPluckAngle;    ///< Angle along zoneLayoutAxis defining the low region of the pluck zones
@property (nonatomic) IMMotionUnit maxPluckAngle;


/** @{
 Reverse the orientation of the positive direction for the given angles. By default yaw, for instance, has low->high as right->left (anti clockwise)
 */
@property (nonatomic) BOOL reversePluckAngleOrientation;
@property (nonatomic) BOOL reverseEngagementAngleOrientation;
/// @}

/// @}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Events
/////////////////////////////////////////////////////////////////////////

@property (nonatomic, weak) id<IMPluckDetectorDelegate> delegate;

/////////////////////////////////////////////////////////////////////////
#pragma mark - Runtime properties
/////////////////////////////////////////////////////////////////////////

@property (atomic, readonly) IMMotionUnit currentPluckAngle;


/**
 Factor by which pluck velocity is multiplied when the device pitch angle
 is at maxEngagementAngle and by which it's divided when at minEngagementAngle (and scaled in between with 
 halfway = 1)
 
 Uses this equation:
 \f$ v_{scaled} = e^(2 * (\ln F_{s}) * (x - 0.5) \f$
 Set to 1 for no scaling.
 */
//@property float pluckVelAugmentFactorForEngagementAngle;  




////////////////////////////////////////////////////////////////////////////////

@end
