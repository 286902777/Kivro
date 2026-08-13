import UIKit

enum KivroMessageSender {
    case currentUser
    case otherUser
}

enum KivroMessageContent {
    case text(String)
    case image(UIImage)
    case voice(url: URL?, duration: TimeInterval, spokenText: String?)
}

struct KivroChatMessage {
    let identifier: UUID
    let senderIdentifier: String
    let sender: KivroMessageSender
    let content: KivroMessageContent

    init(
        identifier: UUID = UUID(),
        senderIdentifier: String,
        sender: KivroMessageSender,
        content: KivroMessageContent
    ) {
        self.identifier = identifier
        self.senderIdentifier = senderIdentifier
        self.sender = sender
        self.content = content
    }
}
