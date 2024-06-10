use rustler::{Atom, Error, NifResult, Binary};
use rustler::types::atom;

#[rustler::nif]
fn supported_platform() -> bool {
    xattr::SUPPORTED_PLATFORM
}

#[rustler::nif]
fn get_xattr(path: String, name: String) -> NifResult<Option<Vec<u8>>> {
    match xattr::get(path, name) {
        Ok(Some(value)) => Ok(Some(value)),
        Ok(None) => Ok(None),
        Err(e) => Err(Error::Term(Box::new(e.to_string())))
    }
}

#[rustler::nif]
fn set_xattr(path: String, name: String, value: Binary) -> NifResult<Atom> {
    match xattr::set(path, name, value.as_slice()) {
        Ok(_) => Ok(atom::ok()),
        Err(e) => Err(Error::Term(Box::new(e.to_string())))
    }
}

#[rustler::nif]
fn list_xattr(path: String) -> NifResult<Vec<String>> {
    match xattr::list(path) {
        Ok(attrs) => attrs.map(|attr| {
            attr.into_string().map_err(|_| Error::Term(Box::new("Failed to convert OsString")))
        }).collect(),
        Err(e) => Err(Error::Term(Box::new(e.to_string())))
    }
}

#[rustler::nif]
fn remove_xattr(path: String, name: String) -> NifResult<Atom> {
    match xattr::remove(path, name) {
        Ok(_) => Ok(atom::ok()),
        Err(e) => Err(Error::Term(Box::new(e.to_string())))
    }
}

rustler::init!("Elixir.ExAttr.Nif", [
    supported_platform,
    get_xattr, 
    set_xattr, 
    list_xattr, 
    remove_xattr,
]);
