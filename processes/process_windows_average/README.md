# process_windows_average
Authors: Edouard Delaire  
Maintainer: @Edouard2laire  
Version: 0.0.1  
Status: alpha  

## Description
This process is equivalent of doing 
(1) Import in databse > Use event as described here:https://neuroimage.usc.edu/brainstorm/Tutorials/Epoching
(2) Average trial as described here: https://neuroimage.usc.edu/brainstorm/Tutorials/Averaging

The only usefullness of this process is that it is able to work on result data (data localized on the cortex after source localization)
This is mainly a workaround as "Import in database" can't be applied on result data

## Screenshots
![process_average_subsets screenshot](./Screenshot.png)

## Known issues
None

## Further Update 
- More function than only average. 
- Rejection of trial based on the presence of rejected segment (bad events)