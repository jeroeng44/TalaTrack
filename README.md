# TalaTrack
**TalaTrack** is an optical motion tracking framework and kinematic analysis pipeline for foot and ankle biomechanics.

![Teaser image](05_figures/cyclic_loading.gif)

# Table of Contents 
- [Getting Started](#getting-started)
  - [Set-up](#set-up)
- [Data Acquisition](#data-acquisition)
- [Motion Tracking Analysis](#motion-tracking-analysis)
- [visualisation](#visualisation)
- [Citation](#citation)
    - [TBD](#tbd)

# Getting Started

## Set-up

Begin by cloning this repository:
```
git clone https://github.com/jeroeng44/TalaTrack.git
cd TalaTrack
```

# Data Acquisition

Motion data acquisition is performed using three dedicated scripts. Depending on the specific experimental setup, the number of markers and marker IDs may need to be adapted.
	1. After marker placement and calibration, the script ZwickCoordConfiguration.m is executed to define the anatomical coordinate system.
	2. Range of motion acquisition, the script ROM_Subtalar.m is used to capture range of motion during the talar tilt test.
	3. Cyclic loading acquisition, Prior to cyclic loading, DataAcquisition.m is executed. Data recording is triggered by the Zwick testing machine during cyclic loading of the specimen.

# Motion Tracking Analysis

Before running the analysis, the data directory should follow the structure below:

```
00_ZwickCoordConfig/
└── *.mat                          % output from ZwickCoordConfiguration.m

01_CT_Data/Segmentation/
├── *.json                         % fiducial marker definitions
├── *.stl                          % bone segmentations
└── ITCL_Vectors.csv               % anatomical axes definitions

02_MotionMarker_Data/
└── ConditionName/
    └── *.mat                      % motion marker recordings

03_Output/
└──                                % processed kinematic data
```

After motion tracking data have been captured and stored according to this structure, analysis is performed using the scripts in the `02_motion_tracking_analysis` folder:

- In `ITCL_011_Get_RelevantDIRs.m`, update the paths to match your local data locations
- Run the main analysis script: `ITCL_010_SingleExp_3DVectorsZwickCoords.m`

Processed kinematic outputs will be saved automatically to the `03_Output` directory.

# Visualisation
The .mlapp file located in the 04_visualisation folder provides an interactive interface to inspect results, visualize bone geometries, and verify transformations in the camera coordinate system. This tool is intended for qualitative validation and sanity checking of the motion-tracking pipeline.


# Citation
If you use TalaTrack in academic work, please cite:
Citation details will be updated upon publication.

```
@article{tbd}
```


