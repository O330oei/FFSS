'use strict'
var prefs=require('./prefs'),letter=require('./cm-apl-mode').letter
var re=RegExp('['+letter+']*$')
var ibeams=[
      '8⌶', // Inverted Table Index-of
     '85⌶', // Execute Expression
    '127⌶', // Overwrite Free Pockets
    '181⌶', // Unsqueezed Type
    '200⌶', // Syntax Colouring
    '219⌶', // Compress/Decompress Vector of Short Integers
    '220⌶', // Serialise/Deserialise Array
    '900⌶', // Called Monadically 950 Loaded Libraries 1111 Number of Threads 1112 Parallel Execution Threshold 1159 Update Function Time and User Stamp 2000 Memory Manager Statistics 2002 Specify Workspace Available 2010 Update DataTable W
   '2011⌶', // Read DataTable W
   '2015⌶', // Create Data Source W
   '2022⌶', // Flush Session Caption W
   '2023⌶', // Close all Windows W
   '2035⌶', // Set Dyalog Pixel Type 2100 Export to Memory W
   '2101⌶', // Close .NET AppDomain W
   '2400⌶', // Set Workspace Save Options 2401 Expose Root Properties 2503 Mark Thread as Uninterruptible 2520 Use Separate Thread For .NET 3002 Disable Component Checksum Validation 3500 Send Text to RIDE-embedded Browser 3501 Connected to the RIDE 3502 Enable RIDE in Run-time Interpreter 4000 Fork New Task X
   '4001⌶', // Change User X
   '4002⌶', // Reap Forked Tasks X
   '4007⌶', // Signal Counts X
   '7159⌶', // JSON Import
   '7160⌶', // JSON Export
   '7161⌶', // JSON TrueFalse
   '7162⌶', // JSON Translate Name
  '16807⌶', // Random Number Generator
  '50100⌶'  // Line Count
]
this.setUp=function(win){ // win: an instance of Editor or Session
  var tid,cm=win.cm,r
  cm.on('change',function(){
    var mode=(cm.getOption('mode')||{}).name
    if(prefs.autocompletion()&&(mode==='apl'||mode==='apl-session')&&cm.getCursor().line){
      clearTimeout(tid)
      tid=setTimeout(function(){
        tid=null;var c=cm.getCursor(),s=cm.getLine(c.line),i=c.ch
        if(s[i-1]==='⌶'&&!/\d *$/.test(s.slice(0,i-1))){
          r(1,ibeams)
        }else if(i&&s[i-1]!==' '&&s.slice(0,i).replace(re,'').slice(-1)!==prefs.prefixKey()&&
                  win.promptType!==4){ // don't autocomplete in ⍞ input
          win.autocompleteWithTab=0;win.emit('GetAutoComplete',{line:s,pos:i,token:win.id})
        }
      },prefs.autocompletionDelay())
    }
  })
  return r=function(skip,options){
    if(prefs.autocompletion()&&options.length&&cm.hasFocus()&&cm.getWrapperElement().ownerDocument.hasFocus()){
      var c=cm.getCursor(),from={line:c.line,ch:c.ch-skip},sel=''
      if(options.length===1&&win.autocompleteWithTab){
        cm.replaceRange(options[0],from,c,'D')
      }else{
        cm.showHint({
          completeOnSingleClick:true,completeSingle:false,
          extraKeys:{
            Enter:function(cm,m){sel?m.pick():cm.execCommand('ER')},
            Right:function(cm,m){sel||m.moveFocus(1);m.pick()},
            'Shift-Tab':function(cm,m){m.moveFocus(-1)},
            Tab:function(cm,m){m.moveFocus(1);options.length===1&&m.pick()}
          },
          hint:function(){
            var to=cm.getCursor(),
                u=cm.getLine(from.line).slice(from.ch,to.ch).toLowerCase(), // completion prefix
                list=u==='⌶'?options:options.filter(function(o){return o.slice(0,u.length).toLowerCase()===u}).sort()
            list.length&&list.unshift('')
            var data={from:from,to:to,list:list};CodeMirror.on(data,'select',function(x){sel=x});return data
          }
        })
      }
    }
  }
}
