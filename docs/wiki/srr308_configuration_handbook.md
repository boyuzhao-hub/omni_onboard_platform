# Continental SRR308-21 Configuration

> [!NOTE]
> The following notes are my personal interpretations based on the official ARS408-21 Radar technical manual.
> 
Continental SRR308-21 Radar is able to provide two outputs with up to 8 radars co-work configuration.
- **Clusters** radar reflections with information (position, velocity and signal strength)
- **Objects** are tracked clusters which have history and dimension information.

## Configuration
- Messge ```RadarCfg```. Radar Configuration related information will be stored with non-volatile memory. Related signals: ```RadarCfg_StoreInNVM``` and ```RadarCfg_StoreInNVM_valid```. 
- Message ```FilterCfg```
  - Signal ```FilterCfg_Type``` decides clusters or objects to be filtered.
  - Signal ```FilterCfg_Index``` indicates the filter criterion
- Message ```CollDetCfg``` only possible with objects.
- Message ```CollDetRegCfg``` indicates the rectangular regions that can be detected.

## Output
- State Output
  - Message ```RadarState``` indicates the current configuration and sensor state. (Sent per second)
  - Message ```VersionID``` indicates the current firmware verions.
  - Message ```FilterState_Header``` indicates the number of configured filters.
  - Message ```FilterState_Cfg``` indicates the filter that has been chosen/configured.
  - Message ```CollDetRegionState``` indicates the the current collision detection.
  - Message ```CollDetRelayCtrl``` indicates the relay when collision detected.
- Cluster List Output
  - Message ```Cluster_0_Status``` the number of near scan clusters.
  - Message ```Cluster_1_Gereral``` position and velocity of clusters and is sent repeatedly for all the detected clusters (start from near scan to far scan). Each of the two cluster lists is range sorted. Only the first 250 clusters are sent.
  - Message ```Cluster_2_Quality``` only sent out if signal ```RadarCfg_SendQuality``` is activated, which contains quality information of the clusters.
  - Note: if multiple clusters exist, the Cluster_2_Quality only will be sent after all the Cluster_1_General sentout.
- Object List Output
  - Message ```Obj_0_Status``` the number of objects will be sent afterwards.
  - Message ```Obj_1_General``` position and velocity of the objects and is sent repeadedly for all the tracked objects.
  - Message ```Obj_2_Quality``` only sent out if signal ```RadarCfg_SendQuality``` is activated, which contains quality information of the objects. 
  - Message ```Obj_3_Extended``` only sent out if signal ```RadarCfg_SendExtInfo``` is activated, which contains additional object properties.
  - Message ```Obj_4_Warning``` only sent out if message ```CollDetCfg``` is activated, which contains the collision detection warning state.
  - Note: if multiple clusters exist, all the messages of type Obj_1_General are sent firstly and afterwards Obj_2_Quality and afterwards Obj_3_Extended and then Obj_4_Warning.

## Input
- Message ```SpeedInformation``` evaluate vehicle speed, is used to determine the movemnet of detecdted clusters and objects.
  - Signal ```RadarDevice_Speed ```
  - Signal ```RadarDevice_SpeedDirection```
- Message ```YawRateInformation```
