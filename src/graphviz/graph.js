//@ts-check
import cytoscape from "./cytoscape.esm.js"

let common_style = {
  node: {
    shape: 'rectangle',
    width: "label",
    height: 'label',
    'text-wrap': 'wrap',
    content: 'data(label)',
    'text-valign': 'center',
    padding: 10,
    'min-width': '10em',
    'font-size': '10px',
    'border-width': '1px',
    'border-color': 'black',
    'border-style': 'solid',
  },
  edge: {
    'target-arrow-shape': 'triangle',
    'target-arrow-color': 'gray',
    'curve-style': 'straight'
  }
}

let default_style = {
  node: 
  {...common_style.node,
    display: 'none',
    'background-color': 'pink',
  },
  edge: {...common_style.edge,
    display: 'none',
  }
}

let visible_style = {
  node: {...common_style.node,
    'background-color': 'lightblue',
  },
  edge: common_style.edge
}

let style = [
  {
    selector: 'node',
    css: default_style.node
  },
  {
    selector: 'edge',
    css: default_style.edge
  }
]

let layouts = {
  concentric: {
    name: 'concentric',
    padding: 0,
    nodeDimensionsIncludeLabels: true,
    fit:false
  },
  bf: {
    name: 'breadthfirst',
    circle: true,
    spacingFactor: 0.3,
    padding: 0,
  },
  cose: {
    name: 'cose',
    animate: 'false',
  }
}

let make = (elts, id) => cytoscape({
  container: document.getElementById(id),
  elements: elts,
  style: style,
  layout : layouts.bf,
  minZoom: 1.0,
})

let make_headless = (elts) => cytoscape({
  elements: elts,
  headless: true,
})

let reset_style = cy => {
  cy.nodes().each(ele => ele.style(default_style.node));
  cy.edges().each(ele => ele.style(default_style.edge));
}

export default { make, reset_style, layouts, make_headless, common_style}
