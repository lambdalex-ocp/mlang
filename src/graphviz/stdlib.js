let make_option = () => {
  let some = payload => {
    return {kind: "some", payload}
  }

  let none = () => ({kind: "none"});

  let is_some = t => t.kind == 'some'
  let is_none = t => t.kind == 'none'

  let get_some = t => {
    if (is_some(t)) {
      return t.payload;
    } else {
      console.log(t);
      throw new Error(`get_some was none: ${t}`);
    }
  }

  let match = (t, args) => {
    if (is_none(t)) {
      args.fnone();
    } else {
      args.fsome(t.payload);
    }
  }

  let bind = (t, f) => {
    if (is_none(t)) { return; }
    return f(t.payload);
  }

  return {some, none, is_some, is_none, get_some, match, bind}
}

export let Option = make_option();

export default { Option }
