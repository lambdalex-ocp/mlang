import {Option} from './stdlib.js'
import Graph from './graph.js'

let draw_graph = (state) => {
  Graph.reset_style(state.cy);
  let draw_all = () => {
    let style = {
      'visibility': 'visible'
    };
    console.log(state.cy.nodes);
    state.cy.nodes().each(ele => ele.style(style));
    state.cy.edges().each(ele => ele.style(style));
  }
  let draw_sub = (var_name) => {
    let root = state.cy.$(`node[var_name = "${var_name}"]`)
    for (let i = 0; i < state.depth; ++i) {
      root = root.union(root.neighbourhood());
    }
    let style = {
      'background-color': 'lightblue',
      'visibility': "visible",
    }
    root.each(ele => ele.style(style))
  };
  let args = {fnone: draw_all, fsome: draw_sub}
  Option.match(state.focus, args);
}

let make = (cy) => {
  let focus = Option.none();
  let depth = 0;
  let state = {focus, depth, cy};
  set_depth(state, depth);
  set_focus(state, focus);
  draw_graph(state);
  return state;
}

let set_focus = (state, focus) => {
  state = {...state, focus};
  draw_graph(state);
  let label = document.querySelector('#focused-var-label');
  label.textContent = focus;
  return state;
}

let set_depth = (state, depth) => {
  state = {...state, depth};
  let elt = document.querySelector('#depth-value');
  let slider = document.querySelector('#depth-slider');
  slider.value = depth;
  elt.textContent = depth;
  draw_graph(state);
  return state;
}

export default {make, set_focus, set_depth}
