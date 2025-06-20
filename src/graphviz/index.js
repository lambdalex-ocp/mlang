//@ts-check
import cytoscape from "./cytoscape.esm.js"
import dot_graph from "./dbg_graph.json" with {type: 'json'}
import Convertor from "./convertor.js"

console.log(dot_graph);
let graph = Convertor.convert(dot_graph);
let var_names = Convertor.get_var_names(dot_graph);
console.log(var_names);

let dom_vnames = document.getElementById('var-list');
let make_div = name => {
  let div = document.createElement('div');
  div.className = "var-name";
  div.innerHTML = name;
  div.addEventListener("click", () => alert(name));
  return div;
}
let divs = var_names.map(make_div);
divs.forEach(div => dom_vnames.appendChild(div));

let style = [
  {
    selector: 'node',
    css: {
      shape: 'rectangle',
      width: 'label',
      height: 'label',
      'text-wrap': 'wrap',
      content: 'data(label)',
      'text-valign': 'center',
      'text-halign': 'center',
      padding: 10,
    }
  }
]

let make_cytoscape = () => cytoscape({
  container: document.getElementById('cy'),
  elements: graph.elements,
  style: style,
  layout : { name: 'grid', rows: 1}
})

let cy = make_cytoscape(graph.elements);
let a = cy.$('X').neighbourhood();
console.log(a);

console.log("We've executed");


