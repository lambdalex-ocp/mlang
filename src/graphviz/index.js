//@ts-check
// import dot_graph from "./dbg_graph.json" with {type: 'json'}
import dbg_graph from "./dbg_graph.js"
import Convertor from "./convertor.js"
import { Option }  from "./stdlib.js"
import State from "./state.js"


let graph = Convertor.convert_from_json(dbg_graph);
console.log(graph);

/* Setup html */

let var_names = Convertor.get_var_names(graph);
let dom_vnames = document.getElementById('var-list');
let make_div = name => {
  let div = document.createElement('div');
  div.className = "var-name btn";
  div.innerHTML = name;
  div.addEventListener("click", () => {
    state = State.set_focus(state, Option.some(name))
  });
  return div;
}
let divs = var_names.map(make_div);
divs.forEach(div => dom_vnames.appendChild(div));

let state = State.make(graph, 'cy');

/* Webpage dynamics */

const reset_focus_btn = document.querySelector("#reset-focus-btn");
reset_focus_btn.addEventListener('click', () => {
  State.set_focus(state, Option.none())
})

