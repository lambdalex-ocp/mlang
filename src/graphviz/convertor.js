//@ts-check
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

let convert_from_json = graph => {
  let add_id = obj => ({data: {...obj.data, id: obj.data.name}});
  return graph.map(elt => add_id(elt))
}

let get_var_names = graph => {
  let names = graph.filter(v => v.data.name != undefined)
    .map(v => v.data.name);
  return names;
}

export default {get_var_names, convert_from_json}
