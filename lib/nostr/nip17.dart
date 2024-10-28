import 'package:nostr/nostr.dart';
import 'package:wallet/src/rust/api/nostr.dart';

class Nip17 {
  void sendMessage(
    String relay,
    String senderSecret,
    String senderPublic,
    String receiverPublic,
    String message,
    String? replyTo,
  ) {
    var rumor = Event.partial(
      pubkey: receiverPublic,
      createdAt: currentUnixTimestampSeconds(),
      kind: 14,
      tags: [
        ["p", receiverPublic, relay],
        ["subject", "some title"],
      ],
      content: message,
    );
    rumor.id = rumor.getEventId();
    // rumor remains unsigned

    var seal = Event.partial(
      pubkey: senderPublic,
      // TODO: randomTimeUpTo2DaysInThePast
      createdAt: currentUnixTimestampSeconds(),
      kind: 13,
      tags: [],
      content: nip44Encrypt(
        secretKey: senderSecret,
        publicKey: receiverPublic,
        plaintext: rumor.serialize(),
      ),
    );
    seal.id = seal.getEventId();
    seal.sig = seal.getSignature(senderSecret);

    var x = nip44ConversationKey(
      secretKey: senderSecret,
      publicKey: receiverPublic,
    );

    var giftWrap = Event.partial(
      pubkey: "randomPubKey",
      createdAt: currentUnixTimestampSeconds(),
      kind: 1059,
      tags: [
        ["p", receiverPublic, relay]
      ],
      content: nip44Encrypt(
        secretKey: "randomPrivateKey",
        publicKey: receiverPublic,
        plaintext: seal.serialize(),
      ),
    );
    giftWrap.id = giftWrap.getEventId();
    giftWrap.sig = giftWrap.getSignature("randomPrivateKey");
  }

  void receiveMessage() {}
}
