# AccuChekKit

Accu-Chek CGM driver for Loop.

**Currently Supported Models:**

- Accu-Chek SmartGuide*

*At the point of writing only European/Dutch SmartGuide sensors have been tested. In case you have another variant (e.g. US), please test it and report your findings by opening a GitHub issue to confirm (in)compatibility.

> Note: There may exist Accu-Chek CGMs with advanced security. These are not yet compatible. \
> At this moment its not known which sensors they are. If you have one/encountered one please open an issue. 

## Troubleshooting

In case an issue is not covered by the FAQ below please reach out on the Loop Zulipchat or open a GitHub issue. 

Please make sure to attach your logs when you file a report. 

You can find them by going to the Accu-Chek settings menu and pressing the "Share Accu-Chek logs" button.

## Frequently Asked Questions

**Q: I've already warmed up the sensor and want to pair it but Trio/Loop can't find it?**

A: In case you still have the SmartGuide app installed it is possible that it is interfering with the discovery of the sensor. Please close the SmartGuide app, wait for 10 seconds, and try searching for the sensor again in Loop/Trio.

**Q: There is a large gap in between my readings, what is happening?**

A: Sometimes your sensor may malfunction (e.g., due to compression). During this time any readings sent are dropped as they are invalid. If you look at the settings panel you should also see that readings are "Unavailable". This is usually temporary and will resolve on its own.

**Q: I calibrated the sensor but now I am back in Trend Mode?**

A: You've missed the second calibration moment. The SmartGuide sensor requires two consecutive calibrations to get to (and stay in) Therapy Mode. You will have to start again from scratch. Please look at the app status for when the next calibration is due.

## More Information

For more information please join the Trio Discord: https://discord.triodocs.org/
