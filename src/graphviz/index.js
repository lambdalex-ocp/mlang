//@ts-check
import dbg_graph from "./new_dbg_graph.json" with {type: 'json'}
// import dbg_graph from "./new_dbg_graph.js"
import Convertor from "./convertor.js"
import { Option }  from "./stdlib.js"
import State from "./state.js"
import Fuse from "./fuse.js"


let graph = Convertor.convert_from_json(dbg_graph.graph);
console.log(graph);

/* Setup html */

let var_names = Convertor.get_var_names(graph);
let vname_fuse = new Fuse(var_names, {includeScore: true, threshold: 0.4});

let update_var_list = (var_names) => {
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
  dom_vnames?.replaceChildren();
  divs.forEach(div => dom_vnames?.appendChild(div));
}

update_var_list(var_names);
let state = State.make(graph, 'cy');

/* Webpage dynamics */

const reset_focus_btn = document.querySelector("#reset-focus-btn");
reset_focus_btn?.addEventListener('click', () => {
  State.set_focus(state, Option.none())
})

const search_input = document.getElementById('var-search-input');
search_input?.addEventListener('input', event => {
  let search_name = event.target?.value;
  if (search_name == "") {
    update_var_list(search_name);
    return;
  }
  let res = vname_fuse.search(search_name);
  update_var_list(res.map(v => v.item));
})

