# QField Ask AI Plugin

This [QField](https://qfield.org) plugin integrates AI searches within QField's search bar. 
The plugin relies on new functionalities within the plugin framework introduced in QField 3.5.

## Installation

To install the plugin, [download the plugin from the releases page](../../releases/latest/download/qfield-ask-ai.zip)
and follow the [plugin installation guide](https://docs.qfield.org/how-to/plugins/#application-plugins) to install
the zipped plugin in QField.

## Usage

To start searches once the plugin is installed, expand the search bar, type
the prefix aai followed by the search string, and wait for the results

## Context variables
QField's Ask AI Plugin supports context variables that will be replaced before the prompt is sent.

### @me
Search: `aai what historical site is near @me?`

Prompt: `what historical site is near latitude 46.94816666666667 and longitude 7.455333333333334?`

### @mapcenter
Search: `aai what castles are near @mapcenter?`

Prompt: `what castles are near latitude 40.67971032370505 and longitude 14.766729803798855?`

### @mapextent
Search: `aai what churches are within @mapextent?`

Prompt: `what churches are within extent 12.4372929651450814,41.8861018043505027 : 12.4861885994769057,41.9166361227203055?`


## credits
icon by icons8.com
