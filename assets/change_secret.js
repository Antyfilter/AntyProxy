const genRanHex = size => [...Array(size)]
  .map(() => Math.floor(Math.random() * 16).toString(16)).join('');

new_secret=genRanHex(32)
codes=document.getElementsByTagName('code')
for (i=0; i<codes.length;i++){
codes[i].innerHTML=codes[i].innerHTML.replaceAll('751F2F753854422EA4C5FDDB8314F068',new_secret)
}
