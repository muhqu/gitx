
var printDebug = function(str) {
    $("debug").innerHTML = "<h2>debug</h2><pre>"+str.escapeHTML()+"</pre>";
}

var changeVersus = function (sele) {
    Controller.changeVersus_(sele.value);
}

var changeRef = function (ref) {
    Controller.changeRef_(ref);
}

var findParent = function (el, tagname) {
    var p = el && el.parentElement;
    if (p) return (p.tagName == tagname.toUpperCase()) ? p : findParent(p, tagname);
    return null;
}
var cnt = 0;
var loadBranchList = function(ag, vs, data) {

    var vshtml = '<select id="vsmode" onchange="changeVersus(this)">';
    for(var i=0; i<vs.length; i++) {
        var active = vs[i][1]=="active";
        vshtml+= '<option'+(active?' selected':'')+'>'+(vs[i][0]||"").escapeHTML()+'</option>';
    }
    vshtml+= '</select>';
    
    var against = { title: ag[0], commit:ag[1], date: ag[2], dttm: ag[3] };
    $("againstinfo").innerHTML = '<h2>'+(against.title).escapeHTML()+' vs. '+vshtml+'</h2>'+
        '<p>Last updated <abbr class="relatize relatized" title="'+against.dttm+'">'+against.date+'</abbr> by '+(against.commit.author).escapeHTML()+'</p>';
    
    if (!data) {
        $("branchlist").onclick = null;
        $("branchlist").innerHTML = 'Loading...';
        printDebug("Loading "+(++cnt));
    } else {
        var branchList=[];
        var maxahead=20;
        for(var i in data) {
            var a = data[i];
            var item = { ref: a[0], title: a[1], behind: a[2], ahead: a[3], commit: a[4], date: a[5], dttm: a[6], freshness: a[7] };
            maxahead = Math.max(maxahead,item.behind,item.ahead);
            branchList[i] = item;
        }
        var branchlistHtml=[];
        for(var i=0; i<branchList.length; i++) {
            var item = branchList[i];
            var commit = item.commit || {};
            item.behindPercent = Math.min(item.behind/200*100, 100);
            item.aheadPercent = Math.min(item.ahead/200*100, 100);
            branchlistHtml.push('<tr id="'+(item.ref).escapeHTML()+'">'+
            '<td class="name">'+
            '<h3>'+(item.title).escapeHTML()+'</h3>'+
            '<p>Last updated <abbr class="relatize relatized" title="'+item.dttm+'">'+item.date+'</abbr> by '+(commit.author).escapeHTML()+'</p></td>'+
            '<td class="state-widget">'+
                '<div class="diverge-widget '+item.freshness+'">'+
                '<span class="behind">'+
                    '<span class="bar" style="width:'+item.behindPercent+'%"></span>'+
                    '<em>'+item.behind+' behind</em>'+
                '</span>'+
                '<span class="ahead">'+
                    '<span class="bar" style="width:'+item.aheadPercent+'%"></span>'+
                    '<em>'+item.ahead+' ahead</em>'+
                '</span>'+
                '<span class="separator"></span>'+
                '</div>'+
            '</td>'+
            '<td class="action"></td>'+
            '</tr>');
        }
        $("branchlist").innerHTML = '<table class="branches">'+
            '<tr><th>Name</th><th class=\"state-widget\">State</th><th></th></tr>\n'+
                branchlistHtml.join('\n')+
            '</table>';
    
        $("branchlist").onclick = function(e){
            var el = e.target && findParent(e.target,"tr");
            var ref = el && el.id;
            if (ref) changeRef(ref);
        }
    }
    // Scroll to top
    scroll(0, 0);
}