#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

use nostr::{
    key::{Keys, PublicKey, SecretKey},
    nips::{
        nip19::{FromBech32, ToBech32},
        nip44,
    },
};

#[flutter_rust_bridge::frb(sync)]
pub fn generate_nostr_keys() -> (String, String) {
    let keys = Keys::generate();
    let secret = keys.secret_key().to_bech32().unwrap();
    let public = keys.public_key().to_bech32().unwrap();
    return (secret, public);
}

#[flutter_rust_bridge::frb(sync)]
pub fn recover_nostr_keys(secret: String) -> (String, String) {
    let secret_key = SecretKey::from_bech32(secret).unwrap();
    let keys = Keys::new(secret_key);
    let secret = keys.secret_key().to_bech32().unwrap();
    let public = keys.public_key().to_bech32().unwrap();
    return (secret, public);
}

#[flutter_rust_bridge::frb(sync)]
pub fn nip44_encrypt(secret_key: String, public_key: String, plaintext: String) -> String {
    let secret_key = SecretKey::from_bech32(secret_key).unwrap();
    let public_key = PublicKey::from_bech32(public_key).unwrap();
    let ciphertext = nip44::encrypt(&secret_key, &public_key, plaintext, nip44::Version::V2);
    return ciphertext.unwrap();
}

#[flutter_rust_bridge::frb(sync)]
pub fn nip44_decrypt(secret_key: String, public_key: String, ciphertext: String) -> String {
    let secret_key = SecretKey::from_bech32(secret_key).unwrap();
    let public_key = PublicKey::from_bech32(public_key).unwrap();
    let plaintext = nip44::decrypt(&secret_key, &public_key, ciphertext);
    return plaintext.unwrap();
}
