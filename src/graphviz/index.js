//@ts-check
import cytoscape from "./cytoscape.esm.js"
import dot_graph from "./dbg_graph.json" with {type: 'json'}
import Convertor from "./convertor.js"
import { Option }  from "./stdlib.js"
import State from "./state.js"
import Graph from "./graph.js"


console.log(dot_graph);
let graph = Convertor.convert(dot_graph);

/* Setup html */

let var_names = Convertor.get_var_names(dot_graph);
let dom_vnames = document.getElementById('var-list');
let make_div = name => {
  let div = document.createElement('div');
  div.className = "var-name";
  div.innerHTML = name;
  div.addEventListener("click", () => {
    state = State.set_focus(state, Option.some(name))
  });
  return div;
}
let divs = var_names.map(make_div);
divs.forEach(div => dom_vnames.appendChild(div));


let cy = Graph.make(graph.elements);
let state = State.make (cy);

/* Webpage dynamics */

const input = document.querySelector("#depth-slider");
input.addEventListener("input", ev => {
  let depth = event.target.value;
  state = State.set_depth(state, depth);
})
