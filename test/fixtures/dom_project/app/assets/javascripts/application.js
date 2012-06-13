// Put a div on it
var div = document.createElement('div');
var attr = document.createAttribute('id');
attr.nodeValue = 'the-only-div';
div.setAttributeNode(attr);
document.body.appendChild(div);
