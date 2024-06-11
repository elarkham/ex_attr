use rustler::{Atom, Error, NifResult, Binary};
use rustler::types::atom;
use rustix::io::Errno;
use std::io;

// Sucess means it will be encoded as an atom (from static string)
// Failure means it will be encoded as a string 
fn io_error_to_atom(err: io::Error) -> Result<&'static str, String> {
    if let Some(code) = err.raw_os_error() {
        match Errno::from_raw_os_error(code) {
            Errno::TOOBIG => Ok("e2big"),
            Errno::ACCESS => Ok("eacces"),
            Errno::INVAL  => Ok("einval"),
            Errno::IO     => Ok("eio"),
            Errno::NODATA => Ok("enodata"),
            Errno::NOENT  => Ok("enoent"),
            Errno::NOMEM  => Ok("enomem"),
            Errno::NOSPC  => Ok("enospc"),
            Errno::PERM   => Ok("eperm"),
            Errno::ROFS   => Ok("erofs"),
            Errno::NOTSUP => Ok("enotsup"),
            _ => Err(err.to_string()),
        }
    } else if err.kind() == io::ErrorKind::Unsupported {
        Ok("enotsup")
    } else {
        Err(err.to_string())
    }
}

#[rustler::nif]
fn supported_platform() -> bool {
    xattr::SUPPORTED_PLATFORM
}

#[rustler::nif]
fn get_xattr(path: String, name: String) -> NifResult<Option<Vec<u8>>> {
    match xattr::get(path, name) {
        Ok(Some(value)) => Ok(Some(value)),
        Ok(None) => Ok(None),
        Err(e) => match io_error_to_atom(e) {
            Ok(atom_str) => Err(Error::Atom(atom_str)),
            Err(msg) => Err(Error::Term(Box::new(msg))),
        },
    }
}

#[rustler::nif]
fn set_xattr(path: String, name: String, value: Binary) -> NifResult<Atom> {
    match xattr::set(path, name, value.as_slice()) {
        Ok(_) => Ok(atom::ok()),
        Err(e) => match io_error_to_atom(e) {
            Ok(atom_str) => Err(Error::Atom(atom_str)),
            Err(msg) => Err(Error::Term(Box::new(msg))),
        },
    }
}

#[rustler::nif]
fn list_xattr(path: String) -> NifResult<Vec<String>> {
    match xattr::list(path) {
        Ok(attrs) => attrs.map(|attr| {
            attr.into_string().map_err(|_| Error::Term(Box::new("Failed to convert OsString".to_string())))
        }).collect(),
        Err(e) => match io_error_to_atom(e) {
            Ok(atom_str) => Err(Error::Atom(atom_str)),
            Err(msg) => Err(Error::Term(Box::new(msg))),
        },
    }
}

#[rustler::nif]
fn remove_xattr(path: String, name: String) -> NifResult<Atom> {
    match xattr::remove(path, name) {
        Ok(_) => Ok(atom::ok()),
        Err(e) => match io_error_to_atom(e) {
            Ok(atom_str) => Err(Error::Atom(atom_str)),
            Err(msg) => Err(Error::Term(Box::new(msg))),
        },
    }
}

rustler::init!("Elixir.ExAttr.Nif", [
    supported_platform,
    get_xattr,
    set_xattr,
    list_xattr,
    remove_xattr,
]);
