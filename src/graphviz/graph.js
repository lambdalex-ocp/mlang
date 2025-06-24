import cytoscape from "./cytoscape.esm.js"

let default_style = {
  node: 
  {
    shape: 'rectangle',
    width: 'label',
    height: 'label',
    'text-wrap': 'wrap',
    content: 'data(label)',
    'text-valign': 'center',
    'text-halign': 'center',
    padding: 10,
    "background-color": 'pink',
    visibility: 'hidden',
  },
  edge: {
    visibility: 'hidden',
    'target-arrow-shape': 'triangle',
    'target-arrow-color': 'gray',
    'curve-style': 'bezier',
  }
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

let make = (elts) => cytoscape({
  container: document.getElementById('cy'),
  elements: elts,
  style: style,
  layout : { name: 'grid', rows: 2}
})

let reset_style = cy => {
  cy.nodes().each(ele => ele.style(default_style.node));
  cy.edges().each(ele => ele.style(default_style.edge));
}

export default { make, reset_style }
