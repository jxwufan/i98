var canemcode=true;
var canimgcode=true;
var canmediacode=true;
var canimgsign=true;
var emotnum=72;

var isSimple=false;
var emotdir='http://www.cc98.org/emot/';

var icondir='http://www.cc98.org/images/files/';
var tdclass;

var languageModeTable = {

};

String.format = function () {
	if (arguments.length == 0)
		return null;

	var str = arguments[0];
	for (var i = 1; i < arguments.length; i++) {
		var re = new RegExp('\\{' + (i - 1) + '\\}', 'gm');
		str = str.replace(re, arguments[i]);
	}
	return str;
}


function removequote(str) {

	var quetomatch = /^"(.*)"$/i.exec(str);

	if (quetomatch != null) {
		return quetomatch[1];
	}
	else {
		return str;
	}
}

function escapeRegExp(str) {
	return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}

function parseArgs(str) {

	var result = {};

	if (str != null && str != undefined) {

		var pattern = /\s*,\s*("[^"]*"|[^\s=]*)\s*=\s*(.[^"]*"|[^\s,]*)/gi;

		var addParam = function (all, name, value) {
			result[removequote(name)] = removequote(value);
			return all;
		}

		str.replace(pattern, addParam);
	}
	return result;
}

function filterArgs(dict, allowedArgsTable) {

	var result = {};

	for (var p in dict) {

		var value = dict[p];

		var allowedValue = allowedArgsTable[p];

		switch (typeof (allowedValue)) {
			case "undefined":
				break;
			case "string":
				if (value.match(allowedValue)) {
					result[p] = value;
				}
				break;
			case "object":

				if (allowedValue instanceof RegExp) {
					if (value.match(allowedValue)) {
						result[p] = value;
					}
				}
				else if (allowedValue instanceof Array) {
					for (var i = 0; i < allowedValue.length; i++) {
						if (allowedValue[i] == value) {
							result[p] = value;
							break;
						}
					}
				}
				break;
		}
	}

	return result;
}

function parseAndFilterArgs(str, allowedArgsTable, defaultValueTable) {
	var table = parseArgs(str);
	var result = filterArgs(table, allowedArgsTable);

	if (defaultValueTable) {
		for (var p in defaultValueTable) {
			if (!result[p]) {
				result[p] = defaultValueTable[p];
			}
		}
	}

	return result;
}

function parseLabelNonBalanced(str, labelName, replaceFunc) {

	var pattern = "\\[{0}(,[^\\]]*)?\\]";
	var realPattern = String.format(pattern, escapeRegExp(labelName));

	var reg = new RegExp(realPattern, "gi");

	return str.replace(reg, replaceFunc);
}

function parseLabel(str, labelName, replaceFunc) {

	var pattern = "\\[{0}(,[^\\]]*)?\\](.*?)\\[\\/{0}\\]";
	var realPattern = String.format(pattern, escapeRegExp(labelName));

	var reg = new RegExp(realPattern, "gi");

	return str.replace(reg, replaceFunc);
}

function searchubb(tagid, posttype, thetdclass) {

	tagid = "#" + tagid;

	tdclass = thetdclass;
	var UbbInnerHtml = $(tagid).html().replace(/\<br\>/g, "<BR>").replace(/\r\n/g, '');
	if (posttype == 3)
		$(tagid).html(ubb.noubb(ubbsigncode(UbbInnerHtml)));
	else {
		var currubb = ubbcode(UbbInnerHtml);
		var preubb = currubb;
		for (var i = 1; i < 10; i++)
			if ((currubb = ubbcode(preubb)) != preubb)
				preubb = currubb;
			else
				break;
		$(tagid).html(ubb.noubb(ubb.code(ubb.noubb(currubb), '', 1)));
	}

	$(tagid).find('.code').each(function (index, element) {

		var language = $(element).attr('data-language');

		var editor = ace.edit(element);

		if (language) {

			var modeName = languageModeTable[language] || language;

			editor.getSession().setMode('ace/mode/' + modeName);
		}

		editor.setTheme("ace/theme/chrome");
		editor.setOptions({ maxLines: 300 });
		editor.getSession().setTabSize(4);
		editor.setReadOnly(true);

	});

}

function ubbSilverlightCode(str) {

	var pattern = /\[SL=(.*?)\](.*?)\[\/SL\]/gi;
	return str.replace(pattern, ubbSilverlightSingleReplace);
}

function ubbSilverlightSingleReplace(all, params, altUbb) {
	var altHtml = ubbcode(altUbb);

	var obj = ubbSilverlightGenerateObject(params);
	ubbSilverlightAttachAltHtml(obj, altHtml);
	ubbSilverlightSetOptions(obj);

	var html = ubbSilverlightBuidHtml(obj);

	return html;
}

function ubbSilverlightBuidHtml(objInfo) {

	if (objInfo == null) {
		return "";
	}

	var result = Silverlight.createObject(
			objInfo.source,
			null,
			null,
			objInfo.params,
			null,
			objInfo.initParams,
			null
		);

	return result;
}


function ubbSilverlightAttachAltHtml(objeInfo, altHtml) {
	if (objeInfo != null) {
		objeInfo.params.alt = altHtml;
	}
}

function ubbSilverlightSetOptions(objInfo) {
	if (objInfo != null) {

		if (objInfo.params.alt == "") {
			delete objInfo.params.alt;
		}

		objInfo.params.enablehtmlaccess = false;
		objInfo.params.allowHtmlPopupWindow = false;
	}
}

function ubbSilverlightGenerateObject(params) {

	var pattern = /("[^"]*"|[^\s,]*)\s*,\s*("[^"]*"|[^\s,]*)(.*)/i;

	var allowedParams = new Array("autoUpgrade", "background", "enableautozoom", "enableCacheVisualization", "enableGPUAcceleration", "enableNavigation", "enableRedrawRegions", "maxframerate", "minRuntimeVersion", "splashscreensource", "width", "height", "windowless");

	for (var i = 0; i < allowedParams.length; i++) {
		allowedParams[i] = allowedParams[i].toLowerCase();
	}

	var match = pattern.exec(params);
	if (match != null) {

		var result = {};

		result.source = removequote(match[1]);
		result.initParams = removequote(match[2]);

		result.params = {};

		var otherParams = match[3];
		var otherPattern = /\s*,\s*("[^"]*"|[^\s=]*)\s*=\s*(.[^"]*"|[^\s,]*)/gi;

		var addParam = function (all, name, value) {
			var realname = removequote(name).toLowerCase();

			if (allowedParams.indexOf(realname) != -1) {
				result.params[removequote(name)] = removequote(value);
			}
			return all;
		}

		otherParams.replace(otherPattern, addParam);

		return result;

	}
	else {
		return null;
	}
}

function ubbAudio(str) {
	return parseLabel(str, "audio", ubbAudioReplaceFunc);
}

function ubbVideo(str) {
	return parseLabel(str, "video", ubbVideoReplaceFunc);
}

function getOwaLink(filePath) {
	if (owaEnabled) {
		return String.format(owaPathFormat, encodeURIComponent(filePath));
	}
	else {
		return null;
	}
}

function tryTestOwaTypes(type, url) {

	var supportedTypes = new Array("doc", "docx", "xls", "xlsx", "ppt", "pptx", "pdf");

	if (supportedTypes.indexOf(type) >= 0) {
		return getOwaLink(url);
	}
	else {
		return null;
	}
}

function ubbUploadReplaceFunc(all, type, _unused1, _unused2, url) {

	var linkPath = tryTestOwaTypes(type, url);

	if (linkPath != null) {
		return String.format('<br /><img src="{0}{1}.gif" title="文件图标" border="0" style="border-style: none;" /> <a href="{2}" title="浏览文件" >点击浏览该文件</a>&nbsp;&nbsp;<a title="下载" href="{3}" download="download">直接下载</a>', icondir, escape(type), linkPath, url);
	}
	else {
		return String.format('<br /><img src="{0}{1}.gif" title="文件图标" border="0" style="border-style: none;" /> <a href="{2}" title="浏览文件" >点击浏览该文件</a>', icondir, escape(type), url);
	}
}


function ubbsigncode(str) {
	var pattern = /(^.*?)\[noubb\](.*?)\[\/noubb\](.*$)/i;
	while (pattern.test(str)) {
		var beforeNoubb = RegExp.$1;
		ubb.storage.noubb.push(RegExp.$2);
		var afterNoubb = RegExp.$3;
		str = beforeNoubb + '{noubb' + ubb.num['noubb'].toString() + '}' + afterNoubb;
		ubb.num['noubb']++;
	}
	str = ubbSilverlightCode(str);
	str = ubb.img(str, 0);
	str = ubb.i(str);
	str = ubb.b(str);
	str = ubb.u(str);
	str = ubb.del(str);
	str = ubb.topic(str);
	str = ubb.board(str);
	//str = ubb.cursor(str);
	str = ubb.user(str);
	str = ubb.color(str);
	str = ubb.share(str);
	str = ubb.filter(str);

	str = ubb.url(str, true);
	return str;
}

var loadImg = function (target) {
	ubb.num['img']++;
	return '<img src="' + target + '" id="resizeable' + ubb.num['img'] + '" onload="resizeImg(\'#resizeable' + ubb.num['img'] + '\')" border="0" />';
}

var resizeImg = function (imgId) {

	var image = $(imgId);

	var maxWidth = image.parents("td").first().width() * 0.90;

	if (image.width() > maxWidth)
		image.width(maxWidth);
}

function copyCode(element) {

	var code = $(element).data('code');
	copy2cb(code);

}

function html_decode(str) {
	var s = "";
	if (str.length == 0) return "";
	s = str.replace(/&amp;/g, "&");
	s = s.replace(/&lt;/g, "<");
	s = s.replace(/&gt;/g, ">");
	s = s.replace(/&nbsp;/g, " ");
	s = s.replace(/&#39;/g, "\'");
	s = s.replace(/&quot;/g, "\"");
	s = s.replace(/<br\s*\/?>/gi, "\n");
	return s;
}

var ubb = {

	num: { 'noubb': 0, 'code': 0, 'img': 0, 'musicAuto': 0, 'video': 0 },
	storage: {
		noubb: [],
		code: [],
		codeSource: []
	},
	color: function (str) {
		return str.replace(/\[color=(.[^\[\"\'\\\(\)\:\;]*)\](.*?)\[\/color\]/gi, "<span style=\"color:$1;\">$2</span>");
	},
	i: function (str) {
		return str.replace(/\[i\](.*?)\[\/i\]/gi, "<i>$1</i>");
	},
	u: function (str) {
		return str.replace(/\[u\](.*?)\[\/u\]/gi, "<u>$1</u>");
	},
	b: function (str) {
		return str.replace(/\[b\](.*?)(\[\/b\])/gi, "<b>$1</b>");
	},
	del: function (str) {
		return str.replace(/\[del\](.*?)(\[\/del\])/gi, '<span style="text-decoration:line-through;">$1</span>');
	},
	cursor: function (str) {
		return str.replace(/\[cursor=([A-Za-z]*)\](.*?)(\[\/cursor\])/gi, '<span style="cursor:$1;">$2</span>');
	},
	english: function (str) {
		return str.replace(/\[english\](.*?)\[\/english\]/gi, "<font face=\"Arial\">$1</font>");
	},
	user: function (str) {
		return str.replace(/\[user\](.[^\[]*)\[\/user\]/gi, "<span onclick=\"window.location.href='dispuser.asp?name=$1'\" style=\"cursor:pointer;\">$1</span>");
	},
	pm: function (str) {
		str = str.replace(/\[pm=(.[^\[\'\"\:\(\)\;]*?)\](.*?)\[\/pm\]/gi, "<a href=\"javascript:;\" onclick=\"window.open(\'messanger.asp?action=new&touser=$1\',\'new_win\',\'width=500,height=400,resizable=yes,scrollbars=1\')\">$2</a>");
		str = str.replace(/\[pm\](.[^\[\'\"\:\(\)\;]*?)\[\/pm\]/gi, "<a href=\"javascript:;\" onclick=\"window.open(\'messanger.asp?action=new&touser=$1\',\'new_win\',\'width=500,height=400,resizable=yes,scrollbars=1\')\">点击此处发送论坛短消息给$1</a>");
		return str;
	},
	noubb: function (content) {
		var pattern = /{noubb([0-9]*)}/i;
		while (pattern.test(content)) {
			var tempNum = RegExp.$1;
			content = content.replace(pattern, '<span class="noubb" id="noubb' + tempNum + '" onDblClick="copy2cb(this.innerHTML)">' + ubb.storage.noubb[tempNum] + '</span>');
		}
		return content;
	},
	code: function (str, lang, flag) {
		if (flag == 1) {
			var pattern = /{codes([0-9]*)}/i;
			while (pattern.test(str)) {
				var tempNum = RegExp.$1;
				str = str.replace(pattern, ubb.storage.code[tempNum]);
			}
			return str;
		} else {
			return codeUbb(str, lang);
		}
	},
	media: function (str) {
		var pattern;
		if (true) {
			if (ubb.num['musicAuto'] < 1) {
				pattern = /\[mp3=1\](.[^\[\'\"\(\)]*)\[\/mp3\]/gi;
				if (pattern.test(str)) {

					str = str.replace(/\[mp3=1\](.[^\[\'\"\(\)]*)\[\/mp3\]/i, '<div style="height:20px; width:240px;border:1px #e4e8ef solid;"><embed src="inc/mp3player.swf" width="240" height="20" type="application/x-shockwave-flash" quality="high" flashvars="mp3=$1' + (allowAutoPlay ? "&autoplay=1" : "") + '&showtime=1"></embed></object></div>');
					ubb.num['musicAuto']++;

				}
			}

			str = str.replace(/\[mp3\](.[^\[\'\"\(\)]*)\[\/mp3\]/gi, '<div style="height:20px; width:240px;border:1px #e4e8ef solid;"><embed src="inc/mp3player.swf" width="240" height="20" type="application/x-shockwave-flash" quality="high" flashvars="mp3=$1&autoplay=0&showtime=1"></embed></object></div>');

			str = str.replace(/\[MP=*([0-9]*),*([0-9]*),*([01]*)\](http:\/\/share\.cc98\.org\/[0-9A-Za-z]*?)(.file)?\[\/MP]/gi, '<embed type="application/x-mplayer2" pluginspage="http://microsoft.com/windows/mediaplayer/en/download/" src="$4" autoStart="0" width="$1" height="$2" />');
			str = str.replace(/\[RM=*([0-9]*),*([0-9]*),*([01]*)\](http:\/\/share\.cc98\.org\/[0-9A-Za-z]*?)(.file)?\[\/RM]/gi, "<OBJECT classid=clsid:CFCDAA03-8BE4-11cf-B84B-0020AFBBCCFA class=OBJECT id=RAOCX width=$1 height=$2><PARAM NAME=SRC VALUE=$4><PARAM NAME=CONSOLE VALUE=Clip1><PARAM NAME=CONTROLS VALUE=imagewindow><param name=\"AutoStart\" value=\"False\"></OBJECT><BR><OBJECT classid=CLSID:CFCDAA03-8BE4-11CF-B84B-0020AFBBCCFA height=32 id=video2 width=$1><PARAM NAME=SRC VALUE=$4><PARAM NAME=AUTOSTART VALUE=0><PARAM NAME=CONTROLS VALUE=controlpanel><PARAM NAME=CONSOLE VALUE=Clip1></OBJECT>");

			str = str.replace(/(\[FLASH\])(http:\/\/share\.cc98\.org\/[0-9A-Za-z]*?)(.file)?(\[\/FLASH\])/gi, "<a href=\"$2\" TARGET=_blank><IMG SRC=pic/swf.gif border=0 alt=点击开新窗口欣赏该FLASH动画! height=16 width=16>[全屏欣赏]</a><BR><object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" width=\"500\" height=\"400\" align=\"middle\"><param name=\"allowScriptAccess\" value=\"never\" /><param name=\"movie\" value=\"$2\" /><param name=\"quality\" value=\"high\" /><param name=\"wmode\" value=\"transparent\" /><param name=\"devicefont\" value=\"true\" /><embed src=\"$2\" quality=\"high\" wmode=\"transparent\" devicefont=\"true\" width=\"500\" height=\"400\" swLiveConnect=true align=\"middle\" allowScriptAccess=\"never\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" " + (allowAutoPlay ? "" : "play=\"false\"") + " /></object>");
			str = str.replace(/(\[FLASH=*([0-9]*),*([0-9]*),*([01]*)\])(http:\/\/share\.cc98\.org\/[0-9A-Za-z]*?)(.file)?(\[\/FLASH\])/gi, "<a href=\"$5\" TARGET=_blank><IMG SRC=pic/swf.gif border=0 alt=点击开新窗口欣赏该FLASH动画! height=16 width=16>[全屏欣赏]</a><BR><object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" width=\"$2\" height=\"$3\" align=\"middle\"><param name=\"allowScriptAccess\" value=\"never\" /><param name=\"movie\" value=\"$5\" /><param name=\"play\" value=\"" + (allowAutoPlay ? "$4" : "false") + "\" /><param name=\"quality\" value=\"high\" /><param name=\"wmode\" value=\"transparent\" /><param name=\"devicefont\" value=\"true\" /><embed src=\"$5\" quality=\"high\" wmode=\"transparent\" devicefont=\"true\" width=\"$2\" height=\"$3\" swLiveConnect=true align=\"middle\" allowScriptAccess=\"never\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" play=\"" + (allowAutoPlay ? "$4" : "false") + "\" /></object>");
			str = str.replace(/(\[FLV\])(http:\/\/share\.cc98\.org\/[0-9A-Za-z]*?)(.file)?(\[\/FLV\])/gi, "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" id=\"flvplayer\" width=\"400\" height=\"320\" align=\"middle\"><param name=\"allowScriptAccess\" value=\"never\" /><param name=\"movie\" value=\"inc/flvplayer.swf?file=$2\" /><param name=\"quality\" value=\"high\" /><param name=\"wmode\" value=\"transparent\" /><param name=\"devicefont\" value=\"true\" /><param name=\"bgcolor\" value=\"#ffffff\" /><embed src=\"inc/flvplayer.swf?file=$2\" quality=\"high\" wmode=\"transparent\" devicefont=\"true\" bgcolor=\"#ffffff\" width=\"400\" height=\"320\" swLiveConnect=true id=\"flvplayer\" name=\"flvplayer\" align=\"middle\" allowScriptAccess=\"never\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" " + (allowAutoPlay ? "" : "play=\"false\"") + " /></object>");
			str = str.replace(/\[FLV=*([0-9]*),*([0-9]*)\](http:\/\/share\.cc98\.org\/[0-9A-Za-z]*?)(.file)?\[\/FLV\]/gi, "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" id=\"flvplayer\" width=\"$1\" height=\"$2\" align=\"middle\"><param name=\"allowScriptAccess\" value=\"never\" /><param name=\"movie\" value=\"inc/flvplayer.swf?file=$3\" /><param name=\"quality\" value=\"high\" /><param name=\"wmode\" value=\"transparent\" /><param name=\"devicefont\" value=\"true\" /><param name=\"bgcolor\" value=\"#ffffff\" /><embed src=\"inc/flvplayer.swf?file=$3\" quality=\"high\" wmode=\"transparent\" devicefont=\"true\" bgcolor=\"#ffffff\" width=\"$1\" height=\"$2\" swLiveConnect=true id=\"flvplayer\" name=\"flvplayer\" align=\"middle\" allowScriptAccess=\"never\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" " + (allowAutoPlay ? "" : "play=\"false\"") + " /></object>");
			str = str.replace(/\[MP=*([0-9]*),*([0-9]*),*([01]*)\](.[^\[\'\"\(\)]*)\[\/MP]/gi, "<object align=middle classid=CLSID:22d6f312-b0f6-11d0-94ab-0080c74c7e95 class=OBJECT id=MediaPlayer width=$1 height=$2 ><param name=\"AutoStart\" value=\"False\"><param name=ShowStatusBar value=-1><param name=Filename value=$4><embed type=application/x-oleobject codebase=http://activex.microsoft.com/activex/controls/mplayer/en/nsmp2inf.cab#Version=5,1,52,701 flename=mp src=$4 autoStart=0 width=$1 height=$2></embed></object>");
			str = str.replace(/\[RM=*([0-9]*),*([0-9]*),*([01]*)\](.[^\[\'\"\(\)]*)\[\/RM]/gi, "<OBJECT classid=clsid:CFCDAA03-8BE4-11cf-B84B-0020AFBBCCFA class=OBJECT id=RAOCX width=$1 height=$2><PARAM NAME=SRC VALUE=$4><PARAM NAME=CONSOLE VALUE=Clip1><PARAM NAME=CONTROLS VALUE=imagewindow><param name=\"AutoStart\" value=\"False\"></OBJECT><BR><OBJECT classid=CLSID:CFCDAA03-8BE4-11CF-B84B-0020AFBBCCFA height=32 id=video2 width=$1><PARAM NAME=SRC VALUE=$4><PARAM NAME=AUTOSTART VALUE=0><PARAM NAME=CONTROLS VALUE=controlpanel><PARAM NAME=CONSOLE VALUE=Clip1></OBJECT>");
			str = str.replace(/(\[FLASH\])(.[^\[\'\"\(\)]*)(\[\/FLASH\])/gi, "<a href=\"$2\" TARGET=_blank><IMG SRC=pic/swf.gif border=0 alt=点击开新窗口欣赏该FLASH动画! height=16 width=16>[全屏欣赏]</a><BR><object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" width=\"500\" height=\"400\" align=\"middle\"><param name=\"allowScriptAccess\" value=\"never\" /><param name=\"movie\" value=\"$2\" /><param name=\"quality\" value=\"high\" /><param name=\"wmode\" value=\"transparent\" /><param name=\"devicefont\" value=\"true\" /><embed src=\"$2\" quality=\"high\" wmode=\"transparent\" devicefont=\"true\" width=\"500\" height=\"400\" swLiveConnect=true align=\"middle\" allowScriptAccess=\"never\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" " + (allowAutoPlay ? "" : "play=\"false\"") + " /></object>");
			str = str.replace(/(\[FLASH=*([0-9]*),*([0-9]*),*([01]*)\])(.[^\[\'\"\(\)]*)(\[\/FLASH\])/gi, "<a href=\"$5\" TARGET=_blank><IMG SRC=pic/swf.gif border=0 alt=点击开新窗口欣赏该FLASH动画! height=16 width=16>[全屏欣赏]</a><BR><object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" width=\"$2\" height=\"$3\" align=\"middle\"><param name=\"allowScriptAccess\" value=\"never\" /><param name=\"movie\" value=\"$5\" /><param name=\"play\" value=\"" + (allowAutoPlay ? "$4" : "false") + "\" /><param name=\"quality\" value=\"high\" /><param name=\"wmode\" value=\"transparent\" /><param name=\"devicefont\" value=\"true\" /><embed src=\"$5\" quality=\"high\" wmode=\"transparent\" devicefont=\"true\" width=\"$2\" height=\"$3\" swLiveConnect=true align=\"middle\" allowScriptAccess=\"never\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" play=\"" + (allowAutoPlay ? "$4" : "false") + "\" /></object>");
			str = str.replace(/(\[FLV\])(.[^\[\'\"\(\)]*)(\[\/FLV\])/gi, "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" id=\"flvplayer\" width=\"400\" height=\"320\" align=\"middle\"><param name=\"allowScriptAccess\" value=\"never\" /><param name=\"movie\" value=\"inc/flvplayer.swf?file=$2\" /><param name=\"quality\" value=\"high\" /><param name=\"wmode\" value=\"transparent\" /><param name=\"devicefont\" value=\"true\" /><param name=\"bgcolor\" value=\"#ffffff\" /><embed src=\"inc/flvplayer.swf?file=$2\" quality=\"high\" wmode=\"transparent\" devicefont=\"true\" bgcolor=\"#ffffff\" width=\"400\" height=\"320\" swLiveConnect=true id=\"flvplayer\" name=\"flvplayer\" align=\"middle\" allowScriptAccess=\"never\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" " + (allowAutoPlay ? "" : "play=\"false\"") + " /></object>");
			str = str.replace(/\[FLV=*([0-9]*),*([0-9]*)\](.[^\[\'\"\(\)]*)\[\/FLV\]/gi, "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" id=\"flvplayer\" width=\"$1\" height=\"$2\" align=\"middle\"><param name=\"allowScriptAccess\" value=\"never\" /><param name=\"movie\" value=\"inc/flvplayer.swf?file=$3\" /><param name=\"quality\" value=\"high\" /><param name=\"wmode\" value=\"transparent\" /><param name=\"devicefont\" value=\"true\" /><param name=\"bgcolor\" value=\"#ffffff\" /><embed src=\"inc/flvplayer.swf?file=$3\" quality=\"high\" wmode=\"transparent\" devicefont=\"true\" bgcolor=\"#ffffff\" width=\"$1\" height=\"$2\" swLiveConnect=true id=\"flvplayer\" name=\"flvplayer\" align=\"middle\" allowScriptAccess=\"never\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\" " + (allowAutoPlay ? "" : "play=\"false\"") + " /></object>");
			str = ubbSilverlightCode(str);
			str = ubbAudio(str);
			str = ubbVideo(str);

		} else {
			str = str.replace(/\[MP=*([0-9]*),*([0-9]*)\](.[^\[\'\"\(\)]*)\[\/MP]/gi, "<a href=$3 target=_blank>$3</a>");
			str = str.replace(/\[RM=*([0-9]*),*([0-9]*)\](.[^\[\'\"\(\)]*)\[\/RM]/gi, "<a href=$3 target=_blank>$3</a>");
			str = str.replace(/(\[FLASH\])(.[^\[\'\"\(\)]*)(\[\/FLASH\])/gi, "<IMG SRC=" + icondir + "swf.gif border=0><a href=$2 target=_blank>$2</a>");
			str = str.replace(/(\[FLASH=*([0-9]*),*([0-9]*)\])(.[^\[\'\"\(\)]*)(\[\/FLASH\])/gi, "<IMG SRC=" + icondir + "swf.gif border=0><a href=$4 target=_blank>$4</a>");

			str = ubbSilverlightCode(str);
			str = ubbAudio(str);
			str = ubbVideo(str);
		}
		return str;
	},
	img: function (str, type) {
		var pattern;
		pattern = /\[img\]http:\/\/(www\.cc98\.org|cc\.zju\.edu\.cn)\/(.[^\[]*)\[\/img\]/gi;
		str = str.replace(pattern, '<span style="cursor:pointer;text-decoration:line-through">该文件已在地震中消失了</span>');
		if (type == 0) {
			if (true) {
				str = str.replace(/\[img\](http:\/\/([a-z]+).cc98.org\/(.[^\[]*))\[\/img\]/ig, '<img src="$1" style="border:0;" onload="if (this.width > 600 || this.height > 300) this.src = \'pic/toobig.jpg\'" />');
				str = str.replace(/\[img\](.[^\[]*)\[\/img\]/ig, '');
			} else {
				pattern = /\[IMG\](http|https|ftp):\/\/(.[^\[\'\"\(\)\:]*)\[\/IMG\]/gi;
				str = str.replace(pattern, "<IMG SRC=\"" + icondir + "gif.gif\" border=0><a onfocus=this.blur() href=\"$1://$2\" target=_blank>$1://$2</a>");
			}
		} else {
			if (true) {
				pattern = /\[IMG=0\](http:\/\/share\.cc98\.org\/[A-Za-z0-9]+)(.file)?\[\/IMG\]/gi;
				str = str.replace(pattern, "<br /><a onfocus=this.blur() href=\"$1\" target=_blank><img src=\"$1\" border=0 alt=\"按此在新窗口浏览图片\" class=\"resizeable\" /></a>");
				pattern = /\[IMG(=1)?\](http:\/\/share\.cc98\.org\/[A-Za-z0-9]+)(.file)?\[\/IMG\]/gi;
				str = str.replace(pattern, '<br /><a onfocus="this.blur();" href="$2" target="_blank" title="按此浏览图片" class="clickloadImage" onclick="this.innerHTML=loadImg(this.href);this.onclick=function(){}; return false;"><img src="' + icondir + 'file.gif" border="0">$2</a>');
				pattern = /\[IMG=0\](.[^\[\'\"\(\)]*)(gif|jpg|jpeg|bmp|png)\[\/IMG\]/gi;
				str = str.replace(pattern, "<br /><a onfocus=this.blur() href=\"$1$2\" target=_blank><img src=\"$1$2\" border=0 alt=\"按此在新窗口浏览图片\" class=\"resizeable\" /></a>");
				pattern = /\[IMG(=1)?\](.[^\[\'\"\(\)]*)(gif|jpg|jpeg|bmp|png)\[\/IMG\]/gi;
				str = str.replace(pattern, '<br /><a onfocus="this.blur();" href="$2$3" target="_blank" title="按此浏览图片" class="clickloadImage" onclick="this.innerHTML=loadImg(this.href);this.onclick=function(){}; return false;"><img src="' + icondir + '$3.gif" border="0">$2$3</a>');
				pattern = /\[UPLOAD=(gif|jpg|jpeg|bmp|png)\](http:\/\/file\.cc98\.org\/.[^\[\'\"\:\(\)]*|http:\/\/\w+\.file\.cc98\.lifetoy\.org\/.[^\[\'\"\:\(\)]*)(gif|jpg|jpeg|bmp|png)\[\/UPLOAD\]/gi;
				str = str.replace(pattern, "<br /><a href=\"$2$1\" target=\"_blank\"><img src=\"$2$1\" border=0 alt=\"按此在新窗口浏览图片\" class=\"resizeable\"></a>");
				pattern = /\[UPLOAD=(gif|jpg|jpeg|bmp|png),0\](http:\/\/file\.cc98\.org\/.[^\[\'\"\:\(\)]*|http:\/\/\w+\.file\.cc98\.lifetoy\.org\/.[^\[\'\"\:\(\)]*)(gif|jpg|jpeg|bmp|png)\[\/UPLOAD\]/gi;
				str = str.replace(pattern, "<br /><a href=\"$2$1\" target=\"_blank\"><img src=\"$2$1\" border=0 alt=\"按此在新窗口浏览图片\" class=\"resizeable\"></a>");
				pattern = /\[UPLOAD=(gif|jpg|jpeg|bmp|png),1\](http:\/\/file\.cc98\.org\/.[^\[\'\"\:\(\)]*|http:\/\/\w+\.file\.cc98\.lifetoy\.org\/.[^\[\'\"\:\(\)]*)(gif|jpg|jpeg|bmp|png)\[\/UPLOAD\]/gi;
				str = str.replace(pattern, '<br /><a onfocus="this.blur();" href="$2$1" target="_blank" title="按此浏览图片" class="clickloadImage" onclick="this.innerHTML=loadImg(this.href);this.onclick=function(){}; return false;"><img src="' + icondir + '$1.gif" border="0">$2$1</a>');
			} else {
				pattern = /\[IMG([=]*)([01]*)\](http|https|ftp):\/\/(.[^\[\'\"\:\(\)]*)\[\/IMG\]/gi;
				str = str.replace(pattern, '<br><a onfocus="this.blur();" href="$3://$4" target="_blank" onclick="this.innerHTML=loadImg(this.href);this.onclick=function(){}; return false;"><img src="' + icondir + 'gif.gif" border="0">$3://$4</a>');
				pattern = /\[UPLOAD=(gif|jpg|jpeg|bmp|png)([,]*)([01]*)\](http:\/\/file\.cc98\.org\/.[^\[\'\"\:\(\)]*|http:\/\/\w+\.file\.cc98\.lifetoy\.org\/.[^\[\'\"\:\(\)]*)(gif|jpg|jpeg|bmp|png)\[\/UPLOAD\]/gi;
				str = str.replace(pattern, '<br><a href="$4$5" target="_blank" class="clickloadImage"  onclick="this.innerHTML=loadImg(this.href);this.onclick=function(){}; return false;"><img src="' + icondir + '$5.gif" border=0>$4$5</a>');
			}
		}
		return str;
	},
	file: function (str) {
		pattern = /\[UPLOAD=(.[^\[\'\"\:\(\)]*?)([,]*)([01]*)\](http:\/\/file\.cc98\.org\/.[^\[\'\"\:\(\)]*)\[\/UPLOAD\]/gi;
		str = str.replace(pattern, ubbUploadReplaceFunc);
		pattern = /\[UPLOAD=(.[^\[\'\"\:\(\)]*)\](.[^\[\'\"\:\(\)]*)\[\/UPLOAD\]/gi;
		str = str.replace(pattern, '<span style="cursor:pointer;text-decoration:line-through">该文件已在地震中消失了</span>');
		return str;
	},
	quotex: function (str) {
		return str.replace(/\[quotex\](.*?)\[\/quotex\]/gi, '<i><blockquote>$1</blockquote></i><br/>');
	},
	box: function (str) {

		var patternColor = /(\w+|\#[0-9A-Fa-f]+)/gi;
		var patternWidth = /\d+/gi;

		var boxAllowedParams = {
			'background-color': patternColor,
			'padding': patternWidth,
			'border-color': patternColor,
			'border-width': patternWidth
		};

		var boxDefaultValueParams = {
			'background-color': '#e4e8ef',
			'padding': '5',
			'border-color': '#6595D6',
			'border-width': '1'
		};

		var boxReplaceFunc = function (all, params, content) {
			var args = parseAndFilterArgs(params, boxAllowedParams, boxDefaultValueParams);

			return String.format("<div style=\"width: 100%; background-color: {0}; padding: {1}px; border: solid {2}px {3} \">{4}</div>", args['background-color'], args['padding'], args['border-width'], args['border-color'], content);
		};

		return parseLabel(str, "box", boxReplaceFunc);
	},

	line: function (str) {

		var patternColor = /(\w+|\#[0-9A-Fa-f]+)/gi;
		var patternWidth = /\d+/gi;

		var lineAllowedParams = {
			'height': patternWidth,
			'color': patternColor
		};

		var lineDefaultValueParams = {
			'height': '1',
			'color': '#6595D6'
		};

		var lineReplaceFunc = function (all, params) {
			var args = parseAndFilterArgs(params, lineAllowedParams, lineDefaultValueParams);

			return String.format("<hr style=\"width: 100%; border: none; height: {0}px; background-color: {1}; \" />", args['height'], args['color']);
		};

		return parseLabelNonBalanced(str, "line", lineReplaceFunc);
	},

	table: function (str) {

		var replaceTable = function (all, style, content) {

			var className = 'tableborder1';

			if (style !== undefined) {
				switch (style) {
					case '0':
						className = 'tableborder0';
						break;
				}
			}

			return String.format("<table style=\"width: 100%;\" cellpadding=\"5\" cellspacing=\"1\" class=\"{1}\">{0}</table>", content, className);
		}

		return str.replace(/\[table(?:\=(\d+))?](.*?)\[\/table]/gi, replaceTable);
	},

	tr: function (str) {

		var replaceTR = function (all, content) {

			return String.format("<tr>{0}</tr>", content);
		}

		return str.replace(/\[tr](.*?)\[\/tr]/gi, replaceTR);
	},

	th: function (str) {
		var replaceTH = function (all, rowSpan, colSpan, content) {
			var str = "<th";

			if (colSpan != undefined) {
				str = str + String.format(" colspan=\"{0}\"", colSpan);
			}

			if (rowSpan != undefined) {
				str = str + String.format(" rowspan=\"{0}\"", rowSpan);
			}

			str = str + String.format(">{0}</th>", content);

			return str;
		}

		return str.replace(/\[th(?:\=(\d+),(\d+))?](.*?)\[\/th]/gi, replaceTH);
	},


	td: function (str) {

		var replaceTD = function (all, rowSpan, colSpan, content) {

			var str = "<td";

			if (colSpan != undefined) {
				str = str + String.format(" colspan=\"{0}\"", colSpan);
			}

			if (rowSpan != undefined) {
				str = str + String.format(" rowspan=\"{0}\"", rowSpan);
			}

			str = str + String.format(" class=\"tablebody1\">{0}</td>", content);

			return str;
		}

		return str.replace(/\[td(?:\=(\d+),(\d+))?](.*?)\[\/td]/gi, replaceTD);
	},

	url: function (str, signatureMode) {

		var pattern;

		var generateFunc = function (url, text, showIcon, allowExternal, format) {

			if (text === null) {
				text = url;
			}

			if (url.match(/^\s*javascript\s*:/gi)) {
				return url;
			}

			if (!allowExternal) {

				var m = /(\w+)\:\/\/([\w\.]+)(\:\d+)?(\/.*)?/gi.exec(url);

				var host = m[2];

				if (host !== "www.cc98.org") {
					return url;
				}
			}

			var coreFormat = '<a href="{0}" target="_blank">{1}</a>';

			if (showIcon) {
				coreFormat = '<img style="vertical-align: middle; border: none;" src="pic/url.gif" alt="URL" /> ' + coreFormat;
			}

			var content = String.format(coreFormat, url, text);
			if (format == null) {
				format = "{0}";
			}

			return String.format(format, content);

		}


		str = str.replace(/\[url\](.[^\[]*)\[\/url\]/gi, function (all, g1) { return generateFunc(g1, null, false, !signatureMode, null); });
		str = str.replace(/\[url=(.[^\[\'\"\(\)]*)\](.*?)\[\/url\]/gi, function (all, g1, g2) { return generateFunc(g1, g2, false, !signatureMode, null); });
		pattern = /^((http|https|ftp|rtsp|mms):(\/\/|\\\\)[A-Za-z0-9\.\/=\?%\-&_~`@\':+!;#]+)/gi;
		str = str.replace(pattern, function (all, g1) { return generateFunc(g1, null, true, !signatureMode, null); });

		pattern = /((http|https|ftp|rtsp|mms):(\/\/|\\\\)[A-Za-z0-9\.\/=\?%\-&_~`@\':+!;#]+)<BR>/gi;
		str = str.replace(pattern, function (all, g1) { return generateFunc(g1, null, true, !signatureMode, "{0}<br />"); });
		pattern = /<BR>((http|https|ftp|rtsp|mms):(\/\/|\\\\)[A-Za-z0-9\.\/=\?%\-&_~`@\':+!;#]+)/gi;
		str = str.replace(pattern, function (all, g1) { return generateFunc(g1, null, true, !signatureMode, "<br />{0}"); });

		return str;
	},
	emotion: function (str) {
		if (true) {
			pattern = /\[em([0-9]+)\]/gi;
			str = str.replace(pattern, "<img src=\"" + emotdir + "em$1.gif\" border=0 align=middle>");
		} else {
			pattern = /\[em(.[^\[\'\"\:\(\)\;]*)\]/gi;
			str = str.replace(pattern, "");
		}
		return str;
	},
	share: function (str) {
		str = str.replace(/\[share=([A-Za-z0-9]*)\](.*?)\[\/share\]/gi, '<img src="' + icondir + 'file.gif" border="0" /><a href="http://share.cc98.org/$1" target="_blank">点此下载 $2</a>');
		str = str.replace(/\[share\]([A-Za-z0-9]*)\[\/share\]/gi, '<img src="' + icondir + 'file.gif" border="0" /><a href="http://share.cc98.org/$1" target="_blank">点此下载 $1 文件</a>');
		return str;
	},
	topic: function (str) {
		str = str.replace(/\[topic=(\d+),(\d+)\](.*?)\[\/topic\]/gi, "<a href=\"/dispbbs.asp?boardid=$1&id=$2\">$3</a>");
		return str;
	},
	board: function (str) {
		str = str.replace(/\[board=(\d+)](.*?)\[\/board\]/gi, "<a href=\"/list.asp?boardid=$1\">$2</a>");
		return str;
	},
	filter: function (str) {
		str = str.replace(/\[SHADOW=*([0-9]*),*(#*[a-z0-9]*),*([0-9]*)\](.*?)\[\/SHADOW]/gi, "<table width=$1 ><tr><td style=\"filter:shadow(color=$2, strength=$3)\">$4</td></tr></table>");
		str = str.replace(/\[GLOW=*([0-9]*),*(#*[a-z0-9]*),*([0-9]*)\](.*?)\[\/GLOW]/gi, "<table width=$1 ><tr><td style=\"filter:glow(color=$2, strength=$3)\">$4</td></tr></table>");
		return str;
	},
	subscription: function (str) {
		return str.replace(/\[subscription=(.[^\[\'\"\:\(\)\;]*?)\](.*?)\[\/subscription\]/gi, "<a href=\"javascript:;\" onclick=\"window.open(\'subscription.asp?action=adduser&topicid=$1\',\'new_win\',\'width=500,height=400,resizable=yes,scrollbars=1\')\">$2</a>");
	},
	nothot: function (str) {
		return str.replace(/\[nothot\](.[^\[]*)\[\/nothot\]/gi, "<span name=\"nothot\">$1</span>");
	},
	font: function (str) {
		return str.replace(/\[font=(.[^\[\'\"\:\(\)\;]*?)\](.*?)\[\/font\]/gi, '<span style="font-family:$1;">$2</span>');
	},
	list: function (str) {
		str = str.replace(/\[\*\]/gi, "<li>");
		str = str.replace(/\[list\](.*?)\[\/list\]/gi, "<ul>$1</ul>");
		str = str.replace(/\[list=(1|a|A)\](.*?)\[\/list\]/gi, "<ul type=\"$1\">$2</ul>");
		return str;
	},
	align: function (str) {
		str = str.replace(/\[float=(left|right)\](.*?)\[\/float\]/gi, "<br style=\"clear: both\"><span style=\"float:$1;\">$2</span>");
		str = str.replace(/\[align=(center|left|right)\](.*?)\[\/align\]/gi, "<div align=\"$1\">$2</div>");
		str = str.replace(/\[right\](.*?)(\[\/right\])/gi, "<div align=\"right\">$1</div>");
		str = str.replace(/\[left\](.*?)(\[\/left\])/gi, "<div align=\"left\">$1</div>");
		str = str.replace(/\[center\](.*?)(\[\/center\])/gi, "<div align=\"center\">$1</div>");
		return str;
	},
	size: function (str) {
		var pattern;
		pattern = /\[size=([0-9]*)(pt|px)*\](.*?)\[\/size\]/i;
		while (pattern.test(str)) {
			var unit = RegExp.$2;
			var size = RegExp.$1;
			if (unit == '') {
				size = size > 7 ? 35 : size * 5;
				str = str.replace(pattern, '<span style="font-size:' + size.toString() + 'px; line-height:150%">$3</span>');
			} else {
				size = size > 35 ? 35 : size;
				str = str.replace(pattern, '<span style="font-size:' + size.toString() + unit.toString() + '; line-height:150%">$3</span>');
			}
		}
		return str;
	},
	noEdit: function (str) {
		if (tdclass == 'tablebody1')
			return str.replace(/\[noedit\]/gi, '[color=#e4e8ef]')
		else
			return str.replace(/\[noedit\]/gi, '[color=#fff]')
	},
	software: function (str) {
		str = str.replace(/\[Software\]\[\/Software\]/ig, '<a href="http://software.cc98.org/" target="_blank"><img src="http://file.cc98.org/uploadfile/2010/10/7/2239942335.jpg" border="0" /></a>');
		return str;
	},

	ruby: function (str) {
		return str.replace(/\[ruby=([^\]]*)]([^\]]*)\[\/ruby\]/ig, '<ruby>$2<rt>$1</rt></ruby>');
	}
}

function ubbcode(str) {
	var pattern;
	pattern = /(^.*?)\[noubb\](.*?)\[\/noubb\](.*$)/i;
	while (pattern.test(str)) {
		var beforeNoubb = RegExp.$1;
		ubb.storage.noubb.push(RegExp.$2);
		var afterNoubb = RegExp.$3;
		str = beforeNoubb + '{noubb' + ubb.num['noubb'].toString() + '}' + afterNoubb;
		ubb.num['noubb']++;
	}
	pattern = /(^.*?)(\[code(.*?)\](.*?)\[\/code\])(.*$)/i;
	while (pattern.test(str)) {
		var beforeCode = RegExp.$1;
		var insideCode = RegExp.$2;
		var language = RegExp.$3;
		var codeSource = RegExp.$4;
		var afterCode = RegExp.$5;
		ubb.storage.codeSource.push(codeSource + '\r\n');
		ubb.storage.code.push(ubb.color(ubb.code(codeSource, language ? language.substr(1) : null, 0)));
		str = beforeCode + '{codes' + ubb.num['code'].toString() + '}' + afterCode;
		ubb.num['code']++;
	}
	 str = ubb.img(str, 1);
	// str = ubb.file(str);
//	 str = ubb.media(str);
	 str = ubb.emotion(str);
	 str = ubb.box(str);
	 str = ubb.line(str);
	//str = ubb.noEdit(str);
	 str = ubb.color(str);
	// str = ubb.share(str);
	// str = ubb.software(str);
	 str = ubb.topic(str);
	 str = ubb.board(str);
	 str = ubb.user(str);
	 str = ubb.pm(str);
	str = ubb.b(str);
	 str = ubb.i(str);
	// str = ubb.u(str);
	 str = ubb.del(str);
	str = ubb.cursor(str);
	// str = ubb.english(str);
	 str = ubb.size(str);
	 str = ubb.align(str);
	 str = ubb.list(str);
	 str = ubb.table(str);
	 str = ubb.tr(str);
	 str = ubb.th(str);
	 str = ubb.td(str);
	 str = ubb.subscription(str);
	 str = ubb.nothot(str);
	 str = ubb.font(str);
	 str = ubb.filter(str);
	 str = ubb.url(str, false);
	 str = ubb.ruby(str);
     str = str.replace(/\n/gi, '<br>')
     str = str.replace(/\[quotex\]/gi, '<blockquote>')
     str = str.replace(/\[\/quotex\]/gi, '</blockquote>')
     str = str.replace(/\[[^\]]*\]/gi, '')
	return str;
}
