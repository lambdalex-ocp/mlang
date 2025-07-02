//@ts-check
import {Option} from './stdlib.js'
import Graph from './graph.js'
import cytoscape from './cytoscape.esm.js';

/**
 * @typedef {Object} state
 * @property {Object} focus
 * @property {Number} depth
 * @property {Object} cy
 * @property {Object} subg
 */

let neighbors_fs = {
  incomers: node => node.incomers(),
  outgoers: node => node.outgoers(),
  neighbors: node => node.neighbors(),
}

/**
 * @param {Object} subg - 
 * @param {Number} depth - 
 * @param {Function} neighbors_f - 
 * @returns {Object} - 
 */
let calc_subg = (subg, depth, neighbors_f) => {
  let root = subg;
  for (let i = 0; i < depth; ++i) {
    root = root.union(neighbors_f(root));
  }
  return root;
}

/**
 * @param {state} state - 
 * @param {String} var_name - 
 * @param {Function} neighbors_f - 
 * @returns {state} - 
 */
let focus_var = (state, var_name, neighbors_f) => {
  let root = state.cy.$(`node[name = "${var_name}"]`)
  let depth = state.depth;
  let subg = calc_subg(root, depth, neighbors_f);
  state.subg = subg;
  state.cy.center(root);
  return state;
}

/**
 * @param {state} state - 
 */
let draw_graph = (state) => {
  Graph.reset_style(state.cy);
  state.cy.elements().hide();
  console.log('state.subg length:', state.subg.nodes().length);
  state.cy.startBatch();
  state.subg.show();
  state.cy.endBatch();
  state.subg.layout(Graph.layouts.cose).run();
  console.log("layout done");
}

/**
 * @param {Array} elts - 
 * @param {string} doc_id - 
 * @returns {state} - 
 */
let make = (elts, doc_id) => {
  let cy = Graph.make(elts, doc_id);
  let focus = Option.none();
  let depth = 0;
  let subg = cy.collection();
  let state = {focus, depth, cy, subg};
  cy.on('cxttap', "node", function(event) {
    let name = event.target.id();
    console.log('something has been clicked:', name);
    state.depth = 1;
    focus_var(state, name, neighbors_fs.outgoers); 
    // unfold_var(state, name);
    draw_graph(state);
  });
  cy.on('click', 'node', event => {
    let name = event.target.id();
    state.depth = 1;
    focus_var(state, name, neighbors_fs.incomers);
    draw_graph(state);
  })
  set_depth(state, depth);
  set_focus(state, focus);
  return state;
}

/**
 * @param {state} state - 
 * @param {Object} focus - 
 * @returns {state} - 
 */
let set_focus = (state, focus) => {
  state = {...state, focus};
  let reset_subg = () => {
    state.subg = state.cy.collection();
  }
  let add_subg = (var_name) => {
    state = focus_var(state, var_name, neighbors_fs.outgoers);
  }
  Option.match(focus, {fnone: reset_subg, fsome: add_subg});
  console.log('subg:', state.subg);
  draw_graph(state);
  let label = document.querySelector('#focused-var-label');
  label.textContent = focus;
  return state;
}

/**
 * @param {state} state - 
 * @param {Number} depth - 
 * @returns {state} - 
 */
let set_depth = (state, depth) => {
  state = {...state, depth};
  let elt = document.querySelector('#depth-value');
  let slider = document.querySelector('#depth-slider');
  state.subg = calc_subg(state.subg, depth, node => node.outgoers());
  slider.value = depth;
  elt.textContent = depth.toString();
  draw_graph(state);
  return state;
}

export default {make, set_focus, set_depth}
