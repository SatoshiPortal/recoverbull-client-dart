#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

use nostr::{
    key::{Keys, PublicKey, SecretKey},
    nips::nip44::{self, v2::ConversationKey},
};

use nostr_sdk::prelude::*;

#[flutter_rust_bridge::frb(sync)]
pub fn generate_nostr_keys() -> (String, String) {
    let keys = Keys::generate();
    let secret = keys.secret_key().to_secret_hex();
    let public = keys.public_key().to_hex();
    return (secret, public);
}

#[flutter_rust_bridge::frb(sync)]
pub fn nip44_encrypt(secret_key: String, public_key: String, plaintext: String) -> String {
    let secret_key = SecretKey::from_hex(secret_key).unwrap();
    let public_key = PublicKey::from_hex(public_key).unwrap();
    let ciphertext = nip44::encrypt(&secret_key, &public_key, plaintext, nip44::Version::V2);
    return ciphertext.unwrap();
}

#[flutter_rust_bridge::frb(sync)]
pub fn nip44_decrypt(secret_key: String, public_key: String, ciphertext: String) -> String {
    let secret_key = SecretKey::from_hex(secret_key).unwrap();
    let public_key = PublicKey::from_hex(public_key).unwrap();
    let plaintext = nip44::decrypt(&secret_key, &public_key, ciphertext);
    return plaintext.unwrap();
}

#[flutter_rust_bridge::frb(sync)]
pub fn nip44_conversation_key(secret_key: String, public_key: String) -> String {
    let secret_key = SecretKey::from_hex(secret_key).unwrap();
    let public_key = PublicKey::from_hex(public_key).unwrap();
    let conversation_key = ConversationKey::derive(&secret_key, &public_key);
    conversation_key.to_string()
}

#[flutter_rust_bridge::frb(sync)]
pub fn recover_nostr_keys(secret: String) -> (String, String) {
    let secret_key = SecretKey::from_hex(secret).unwrap();
    let keys = Keys::new(secret_key);
    let secret = keys.secret_key().to_secret_hex();
    let public = keys.public_key().to_hex();
    return (secret, public);
}

#[flutter_rust_bridge::frb(async)]
pub async fn send_private_message(
    relay_url: String,
    sender_secret_key: String,
    receiver_public_key: String,
    plaintext: String,
    reply_to: Option<String>,
) -> String {
    let sender_keys = recover_nostr_keys(sender_secret_key);
    let sender_secret = sender_keys.0;
    let sender_public = sender_keys.1;
    let receiver_public = PublicKey::from_hex(receiver_public_key).unwrap();

    let client = Client::new(&sender_keys);

    let private_message = client
        .send_private_msg_to([relay_url], receiver_public, plaintext, reply_to)
        .await;

    match private_message {
        Ok(value) => value.to_hex(),
        Err(error) => None,
    }
}
