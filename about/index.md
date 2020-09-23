---
layout: page
current: about
title: About
navigation: true
class: page-template
subclass: 'post page'
permalink: /about/
---

### Contact me

To get in touch you can email me at jonathan at this domain or message me on linked in or twitter.

### Countries I have visited

A list of countries I have <a href="https://www.amcharts.com/visited_countries/#AT,BE,BG,HR,CZ,DK,FI,FR,DE,GI,GR,HU,IE,IT,PL,PT,RS,SI,ES,SE,GB,VA,US,MA,CN,IL,JP,TW">visited</a>. A lot done, a lot to do.

<script src="https://www.amcharts.com/lib/3/ammap.js" type="text/javascript"></script>
<script src="https://www.amcharts.com/lib/3/maps/js/worldHigh.js" type="text/javascript"></script>
<script src="https://www.amcharts.com/lib/3/themes/dark.js" type="text/javascript"></script>
<div id="mapdiv" style="width: 1000px; height: 450px;"></div>
<div style="width: 1000px; font-size: 70%; padding: 5px 0; text-align: center; background-color: #535364; margin-top: 1px; color: #B4B4B7;"><a href="https://www.amcharts.com/visited_countries/" style="color: #B4B4B7;">Create your own visited countries map</a> or check out the <a href="https://www.amcharts.com/" style="color: #B4B4B7;">JavaScript Charts</a>.</div>
<script type="text/javascript">
var map = AmCharts.makeChart("mapdiv",{
type: "map",
theme: "dark",
projection: "mercator",
panEventsEnabled : true,
backgroundColor : "#535364",
backgroundAlpha : 1,
zoomControl: {
zoomControlEnabled : true
},
dataProvider : {
map : "worldHigh",
getAreasFromMap : true,
areas :
[
	{
		"id": "AT",
		"showAsSelected": true
	},
	{
		"id": "BE",
		"showAsSelected": true
	},
	{
		"id": "BG",
		"showAsSelected": true
	},
	{
		"id": "HR",
		"showAsSelected": true
	},
	{
		"id": "CZ",
		"showAsSelected": true
	},
	{
		"id": "DK",
		"showAsSelected": true
	},
	{
		"id": "FI",
		"showAsSelected": true
	},
	{
		"id": "FR",
		"showAsSelected": true
	},
	{
		"id": "DE",
		"showAsSelected": true
	},
	{
		"id": "GI",
		"showAsSelected": true
	},
	{
		"id": "GR",
		"showAsSelected": true
	},
	{
		"id": "HU",
		"showAsSelected": true
	},
	{
		"id": "IE",
		"showAsSelected": true
	},
	{
		"id": "IT",
		"showAsSelected": true
	},
	{
		"id": "PL",
		"showAsSelected": true
	},
	{
		"id": "PT",
		"showAsSelected": true
	},
	{
		"id": "RS",
		"showAsSelected": true
	},
	{
		"id": "SI",
		"showAsSelected": true
	},
	{
		"id": "ES",
		"showAsSelected": true
	},
	{
		"id": "SE",
		"showAsSelected": true
	},
	{
		"id": "GB",
		"showAsSelected": true
	},
	{
		"id": "VA",
		"showAsSelected": true
	},
	{
		"id": "US",
		"showAsSelected": true
	},
	{
		"id": "MA",
		"showAsSelected": true
	},
	{
		"id": "CN",
		"showAsSelected": true
	},
	{
		"id": "IL",
		"showAsSelected": true
	},
	{
		"id": "JP",
		"showAsSelected": true
	},
	{
		"id": "TW",
		"showAsSelected": true
	}
]
},
areasSettings : {
autoZoom : true,
color : "#B4B4B7",
colorSolid : "#84ADE9",
selectedColor : "#84ADE9",
outlineColor : "#666666",
rollOverColor : "#9EC2F7",
rollOverOutlineColor : "#000000"
}
});
</script>
