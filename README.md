# Firlib
Firlib (Fannys irlib) is a GUI-wrapper for [irlib](https://github.com/njwilson23/irlib/). Irlib is a set of Python tools in order to view and analyze ice penetrating radar data, written by Nat Wilson.

![Firlib](https://github.com/cr3ation/Firlib/blob/master/docs/img/firlib.png)


## Prerequisites
In order to use Firlib you need:
  - macOS 10.13 or above.
  - Python with the [following](https://github.com/njwilson23/irlib/blob/master/README.md#dependencies) modules installed. 
  - A fully working [irlib](https://github.com/njwilson23/irlib/) installation. Please follow this [tutorial](https://github.com/njwilson23/irlib/blob/master/doc/doc_tutorial.rst) and make sure try every step in the terminal before using Firlib.

## Initial setup
First time you use Firlib you are required to go to _Preferences... (⌘,)_ and
  - Select Python binary.
  - Select irlib root folder.
  - Choose antenna spacing. Needed to calculate ice thickness.

![Settings](https://github.com/cr3ation/Firlib/blob/master/docs/img/preferences_settings.png)

## Usage
Firlib is built to use a linear workflow from top to bottom. In this example we use file ``data/gl3_radar_2012.h5``

![Settings](https://github.com/cr3ation/Firlib/blob/master/docs/img/firlib_example_01.png)
1. On top, begin with selecting a data file to work with. This is the ``.h5``-files is the ``data`` folder of the irlib root.
2. If no metadata has been generated **Dump meta** appear grey. Click the button to generate metadata. It creates a .CSV stored under ``data/gl3_radar_2012_utm_metadata.csv``. The button will appear green when created. Click the button agin to open the file in macOS default application for open CSV-files.
3. **Generate UTM-coordinates**. This creates ``data/gl3_radar_2012_utm.h5``. See irlib documentation about [UTM coordinates](https://github.com/njwilson23/irlib/blob/master/doc/doc_tutorial.rst#utm-coordinates) to know more.
4. **Caches** is optional in irlib but required in Firlib. The number of files generated is equal to number of lines in survey and listed in the GUI to help keep track of progress. Caches are stored in ``cache/``.
5. **Picked** is yellow as long as not all lines are picked – then it turns green. Picked lines are listed to the right. Click to start [icepick2](https://github.com/njwilson23/irlib/blob/master/doc/doc_tutorial.rst#ice-thickness-picking). It defaults to line 0. You can change line inside icepick2 console.
5. **Rated** is yellow as long as not all lines are rated – then it turns green. All rated lines are listed to the right. Click to start icerate. It defaults to the first picked line. You can change line inside icerate console. Rating values are found [here](https://github.com/njwilson23/irlib/blob/master/doc/doc_tutorial.rst#pick-rating).
6. **Offsets** reads fid numbers from ``data/gl3_radar_2012_utm_metadata.csv``, adds antenna spacing and exports it ``offsets/`` folder. This file is needed to calculate ice thickness. Click the green button to read the file.
7. **Ice thickness** does magic and the end result is saved in ``result/depth_gl3_radar_2012_utm.xyz``. Click the green button to read the file. It will look something like

![Firlib](https://github.com/cr3ation/Firlib/blob/master/docs/img/ice_thickness.png)
