/* consumes a dot json and converts it to something
 * usable by cytoscape */
let convert = graph => {
  let conv_object = obj => {
    let id = obj._gvid;
    let label = obj.label;
    let var_name = obj.comment;
    return {data: {id, label, var_name}};
  }
  let objects = graph.objects.map(conv_object);
  let conv_edge = obj => {
    let source = obj.head;
    let target = obj.tail;
    let id = "edge_" + obj._gvid;
    return {data: {source, target, id}};
  }
  let edges = graph.edges.map(conv_edge);
  let elements = objects.concat(edges);
  let ret = {elements};
  console.log(ret);
  return ret;
}

let get_var_names = dotg => {
  let get_vname = obj => obj.comment;
  return dotg.objects.map(get_vname)
}

export default {convert, get_var_names}
