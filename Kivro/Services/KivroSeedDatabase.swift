import CoreData
import Foundation

struct KivroStoredUser {
    let identifier: String
    let username: String
    let gender: String
    let category: String
    let avatarAssetName: String
    let email: String
    let password: String
    let radarCopy: String?
    let isRadarProfile: Bool
    let birthday: Date?
    let countryCode: String?
}

enum KivroRegistrationError: Error {
    case duplicateEmail
}

enum KivroPasswordResetError: Error {
    case accountNotFound
}

struct KivroStoredPost {
    let identifier: String
    let authorIdentifier: String
    let category: String
    let mediaAssetName: String
    let body: String
    let likeCount: Int
    let commentCount: Int
    let isVideo: Bool
}

struct KivroStoredComment {
    let identifier: String
    let postIdentifier: String
    let authorIdentifier: String
    let authorName: String
    let avatarAssetName: String
    let body: String
    let createdAt: Date
}

struct KivroStoredChatMessage {
    let identifier: String
    let senderIdentifier: String
    let recipientIdentifier: String
    let body: String
    let contentType: String
    let mediaData: Data?
    let duration: TimeInterval
    let createdAt: Date
}

struct KivroStoredConversationPreview {
    let user: KivroStoredUser
    let lastMessage: String
    let updatedAt: Date
}

struct KivroDeletedAccountArtifacts {
    let mediaPaths: [String]
}

extension Notification.Name {
    static let kivroPostEngagementDidChange = Notification.Name(
        KivroConstantMask.join("kivro.post.", "engagement.did.", "change")
    )
    static let kivroChatMessagesDidChange = Notification.Name(
        KivroConstantMask.join("kivro.chat.", "messages.did.", "change")
    )
    static let kivroFollowStateDidChange = Notification.Name(
        KivroConstantMask.join("kivro.follow.", "state.did.", "change")
    )
    static let kivroBlockStateDidChange = Notification.Name(
        KivroConstantMask.join("kivro.block.", "state.did.", "change")
    )
}

final class KivroSeedDatabase {
    static let shared = KivroSeedDatabase()

    private static let socialRelationshipSeedKey = KivroConstantMask.join(
        "kivro.seed.", "social-relationships.", "v2"
    )
    private static let seedPassword = KivroConstantMask.join("12", "34", "56")
    private static let sorenEmail = KivroConstantMask.join("te", "st@", "gmail.com")
    private static let seedEmailDomain = KivroConstantMask.join("@gm", "ail.", "com")

    private enum Entity {
        static let user = "KivroUser"
        static let post = "KivroPost"
        nonisolated static let comment = "KivroComment"
        nonisolated static let like = "KivroLike"
        static let follow = "KivroFollow"
        static let block = "KivroBlock"
        static let chatMessage = "KivroChatMessage"
    }

    private struct SeedRecord {
        let username: String
        let gender: String
        let category: String
        let avatarAssetName: String
        let mediaAssetName: String?
        let body: String?
        let radarCopy: String?
        let comment: String?

        var identifier: String { username.lowercased() }
        var email: String {
            username == "Soren"
                ? KivroSeedDatabase.sorenEmail
                : KivroConstantMask.join(username.lowercased(), KivroSeedDatabase.seedEmailDomain)
        }
        var isRadarProfile: Bool { radarCopy?.isEmpty == false }
    }

    private static let seedRecords: [SeedRecord] = [
        .init(
            username: "Soren",
            gender: "male",
            category: "Gothic",
            avatarAssetName: "m1",
            mediaAssetName: "f44ed62ce9971c73e02827b5aca0dbc4",
            body: "Foam armor complete! Ready to bring my Gothic Sorcerer OC to life.",
            radarCopy: nil,
            comment: nil
        ),
        .init(
            username: "Freja",
            gender: "female",
            category: "Cyber",
            avatarAssetName: "w6",
            mediaAssetName: "10c3ce65ca0abfe0f5a0a6ed12bf496c",
            body: "Meow from the neon grid 🐾⚡ Neon lights, holographic vibes, and a touch of cyber-katana.",
            radarCopy: nil,
            comment: "Absolutely love this!"
        ),
        .init(
            username: "Tiernan",
            gender: "male",
            category: "Mecha",
            avatarAssetName: "m2",
            mediaAssetName: "aa6f52fad4fa275dfec71a5f95572c1e",
            body: "LED test inside my DIY Sci-Fi pilot helmet. Visor HUD effect working perfectly!",
            radarCopy: nil,
            comment: nil
        ),
        .init(
            username: "Becker",
            gender: "female",
            category: "Cyber",
            avatarAssetName: "w7",
            mediaAssetName: "08332da58f7cbc4b32ff36316ba69d2f",
            body: "First camera test with my original Cyber Samurai costume! The neon katana blade turned out even better than planned.",
            radarCopy: nil,
            comment: "Amazing work!"
        ),
        .init(
            username: "Carol",
            gender: "female",
            category: "Period",
            avatarAssetName: "w0",
            mediaAssetName: "07cd71340addd1d55b6f1babc16b0462",
            body: "Final test with my original Steampunk costume for this weekends convention!",
            radarCopy: nil,
            comment: nil
        ),
        .init(
            username: "May",
            gender: "female",
            category: "Fantasy",
            avatarAssetName: "w8",
            mediaAssetName: "ac84882f78d328c470f870e3030639a2_720w",
            body: "Trained any dragons lately? Spent weeks working on the fur & armor details for Astrid! What do you think?",
            radarCopy: nil,
            comment: "Top tier build!"
        ),
        .init(
            username: "Thalia",
            gender: "female",
            category: "Cyber",
            avatarAssetName: "w4",
            mediaAssetName: nil,
            body: nil,
            radarCopy: "Just calibrated my neural neon visor. Do you prefer high-voltage cyan or violet lighting for night walks in the grid?",
            comment: nil
        ),
        .init(
            username: "Kasper",
            gender: "male",
            category: "Mecha",
            avatarAssetName: "m4",
            mediaAssetName: nil,
            body: nil,
            radarCopy: "Diagnostic complete! My mecha armor's servo motors are running smoothly. Quick vote: should I go with matte titanium or rusted wasteland paint for the shoulder plates?",
            comment: nil
        ),
        .init(
            username: "Yannick",
            gender: "female",
            category: "Anime",
            avatarAssetName: "w5",
            mediaAssetName: nil,
            body: nil,
            radarCopy: "Incoming call from Space Sector 7! My glowing star wand just lit up—looks like our electronic waves matched!",
            comment: nil
        ),
        .init(
            username: "Dorian",
            gender: "male",
            category: "Gothic",
            avatarAssetName: "m5",
            mediaAssetName: nil,
            body: nil,
            radarCopy: "The midnight velvet curtain rises. I found this obsidian pendant while tailoring my gothic sorcerer cloak—do you believe in ancient curses, stranger?",
            comment: nil
        ),
        .init(
            username: "Freya",
            gender: "female",
            category: "Fantasy",
            avatarAssetName: "w1",
            mediaAssetName: nil,
            body: nil,
            radarCopy: "A whispering breeze brought your message across the enchanted forest! Are you a fellow wanderer seeking the hidden crystal spring?",
            comment: nil
        ),
        .init(
            username: "Arthur",
            gender: "male",
            category: "Period",
            avatarAssetName: "m6",
            mediaAssetName: nil,
            body: nil,
            radarCopy: "Clockwork gears activated! My steam-powered barometer just registered a spike in energy.",
            comment: nil
        )
    ]

    private let context: NSManagedObjectContext
    private let chatContext: NSManagedObjectContext

    private init() {
        let model = Self.makeManagedObjectModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        self.context = context

        let chatModel = Self.makeChatManagedObjectModel()
        let chatCoordinator = NSPersistentStoreCoordinator(managedObjectModel: chatModel)
        let chatContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        chatContext.persistentStoreCoordinator = chatCoordinator
        self.chatContext = chatContext

        do {
            let storeURL = try Self.makeStoreURL()
            try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )
            try chatCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: try Self.makeChatStoreURL(),
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )
            try seedIfNeeded()
            try applyDataCorrections()
        } catch {
            assertionFailure("Unable to initialize the local database.")
        }
    }

    func authenticate(email: String, password: String) -> KivroStoredUser? {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.user)
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "email ==[c] %@ AND password == %@",
            email.trimmingCharacters(in: .whitespacesAndNewlines),
            password
        )
        return (try? context.fetch(request).first).flatMap(Self.makeStoredUser)
    }

    func hasUser(email: String) -> Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.user)
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "email ==[c] %@",
            email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        )
        return ((try? context.count(for: request)) ?? 0) > 0
    }

    func updatePassword(email: String, newPassword: String) throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.user)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "email ==[c] %@", normalizedEmail)
        guard let user = try context.fetch(request).first else {
            throw KivroPasswordResetError.accountNotFound
        }
        user.setValue(newPassword, forKey: "password")
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    @discardableResult
    func registerUser(
        identifier: String,
        username: String,
        gender: String,
        birthday: Date,
        countryCode: String,
        avatarAssetName: String,
        email: String,
        password: String
    ) throws -> KivroStoredUser {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !hasUser(email: normalizedEmail) else {
            throw KivroRegistrationError.duplicateEmail
        }
        let user = NSEntityDescription.insertNewObject(forEntityName: Entity.user, into: context)
        user.setValue(identifier, forKey: "identifier")
        user.setValue(username, forKey: "username")
        user.setValue(gender, forKey: "gender")
        user.setValue("General", forKey: "category")
        user.setValue(avatarAssetName, forKey: "avatarAssetName")
        user.setValue(normalizedEmail, forKey: "email")
        user.setValue(password, forKey: "password")
        user.setValue(nil, forKey: "radarCopy")
        user.setValue(false, forKey: "isRadarProfile")
        user.setValue(birthday, forKey: "birthday")
        user.setValue(countryCode, forKey: "countryCode")
        user.setValue(Date(), forKey: "createdAt")
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        guard let storedUser = Self.makeStoredUser(user) else {
            throw CocoaError(.coderInvalidValue)
        }
        return storedUser
    }

    func user(identifier: String) -> KivroStoredUser? {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.user)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "identifier == %@", identifier)
        return (try? context.fetch(request).first).flatMap(Self.makeStoredUser)
    }

    func radarUsers() -> [KivroStoredUser] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.user)
        request.predicate = NSPredicate(format: "isRadarProfile == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
        return (try? context.fetch(request))?.compactMap(Self.makeStoredUser) ?? []
    }

    func posts() -> [KivroStoredPost] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.post)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request))?.compactMap(Self.makeStoredPost) ?? []
    }

    func posts(authorIdentifier: String) -> [KivroStoredPost] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.post)
        request.predicate = NSPredicate(format: "authorIdentifier == %@", authorIdentifier)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request))?.compactMap(Self.makeStoredPost) ?? []
    }

    @discardableResult
    func addPost(
        authorIdentifier: String,
        category: String,
        mediaAssetName: String,
        body: String,
        isVideo: Bool
    ) throws -> KivroStoredPost {
        let post = NSEntityDescription.insertNewObject(forEntityName: Entity.post, into: context)
        let storedPost = KivroStoredPost(
            identifier: UUID().uuidString.lowercased(),
            authorIdentifier: authorIdentifier,
            category: category,
            mediaAssetName: mediaAssetName,
            body: body,
            likeCount: 0,
            commentCount: 0,
            isVideo: isVideo
        )
        post.setValue(storedPost.identifier, forKey: "identifier")
        post.setValue(storedPost.authorIdentifier, forKey: "authorIdentifier")
        post.setValue(storedPost.category, forKey: "category")
        post.setValue(storedPost.mediaAssetName, forKey: "mediaAssetName")
        post.setValue(storedPost.body, forKey: "body")
        post.setValue(Int64(0), forKey: "likeCount")
        post.setValue(storedPost.isVideo, forKey: "isVideo")
        post.setValue(Date(), forKey: "createdAt")
        try context.save()
        NotificationCenter.default.post(name: .kivroPostStoreDidChange, object: nil)
        return storedPost
    }

    func isFollowing(sourceIdentifier: String, targetIdentifier: String) -> Bool {
        guard sourceIdentifier != targetIdentifier else { return false }
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.follow)
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "sourceIdentifier == %@ AND targetIdentifier == %@",
            sourceIdentifier,
            targetIdentifier
        )
        return ((try? context.count(for: request)) ?? 0) > 0
    }

    func canChat(between firstUserIdentifier: String, and secondUserIdentifier: String) -> Bool {
        guard firstUserIdentifier != secondUserIdentifier,
              !isBlocked(sourceIdentifier: firstUserIdentifier, targetIdentifier: secondUserIdentifier),
              !isBlocked(sourceIdentifier: secondUserIdentifier, targetIdentifier: firstUserIdentifier) else {
            return false
        }
        return isFollowing(sourceIdentifier: firstUserIdentifier, targetIdentifier: secondUserIdentifier)
            && isFollowing(sourceIdentifier: secondUserIdentifier, targetIdentifier: firstUserIdentifier)
    }

    func socialCounts(for userIdentifier: String) -> (following: Int, followers: Int) {
        let followingRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.follow)
        followingRequest.predicate = NSPredicate(format: "sourceIdentifier == %@", userIdentifier)
        let followerRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.follow)
        followerRequest.predicate = NSPredicate(format: "targetIdentifier == %@", userIdentifier)
        return (
            (try? context.count(for: followingRequest)) ?? 0,
            (try? context.count(for: followerRequest)) ?? 0
        )
    }

    func setFollowing(
        _ following: Bool,
        sourceIdentifier: String,
        targetIdentifier: String
    ) throws {
        guard sourceIdentifier != targetIdentifier else { return }
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.follow)
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "sourceIdentifier == %@ AND targetIdentifier == %@",
            sourceIdentifier,
            targetIdentifier
        )
        let existing = try context.fetch(request).first
        if following, existing == nil {
            let record = NSEntityDescription.insertNewObject(forEntityName: Entity.follow, into: context)
            record.setValue(UUID().uuidString.lowercased(), forKey: "identifier")
            record.setValue(sourceIdentifier, forKey: "sourceIdentifier")
            record.setValue(targetIdentifier, forKey: "targetIdentifier")
            record.setValue(Date(), forKey: "createdAt")
        } else if !following, let existing {
            context.delete(existing)
        }
        if context.hasChanges { try context.save() }
        NotificationCenter.default.post(
            name: .kivroFollowStateDidChange,
            object: nil,
            userInfo: ["sourceIdentifier": sourceIdentifier, "targetIdentifier": targetIdentifier]
        )
    }

    func followingUsers(for userIdentifier: String) -> [KivroStoredUser] {
        usersLinkedByRecords(
            entityName: Entity.follow,
            predicate: NSPredicate(format: "sourceIdentifier == %@", userIdentifier),
            userIdentifierKey: "targetIdentifier"
        )
    }

    func followerUsers(for userIdentifier: String) -> [KivroStoredUser] {
        usersLinkedByRecords(
            entityName: Entity.follow,
            predicate: NSPredicate(format: "targetIdentifier == %@", userIdentifier),
            userIdentifierKey: "sourceIdentifier"
        )
    }

    func blockedUsers(for userIdentifier: String) -> [KivroStoredUser] {
        usersLinkedByRecords(
            entityName: Entity.block,
            predicate: NSPredicate(format: "sourceIdentifier == %@", userIdentifier),
            userIdentifierKey: "targetIdentifier"
        )
    }

    func isBlocked(sourceIdentifier: String, targetIdentifier: String) -> Bool {
        guard sourceIdentifier != targetIdentifier else { return false }
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.block)
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "sourceIdentifier == %@ AND targetIdentifier == %@",
            sourceIdentifier,
            targetIdentifier
        )
        return ((try? context.count(for: request)) ?? 0) > 0
    }

    func setBlocked(
        _ blocked: Bool,
        sourceIdentifier: String,
        targetIdentifier: String
    ) throws {
        guard sourceIdentifier != targetIdentifier else { return }
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.block)
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "sourceIdentifier == %@ AND targetIdentifier == %@",
            sourceIdentifier,
            targetIdentifier
        )
        let existing = try context.fetch(request).first
        if blocked, existing == nil {
            let record = NSEntityDescription.insertNewObject(forEntityName: Entity.block, into: context)
            record.setValue(UUID().uuidString.lowercased(), forKey: "identifier")
            record.setValue(sourceIdentifier, forKey: "sourceIdentifier")
            record.setValue(targetIdentifier, forKey: "targetIdentifier")
            record.setValue(Date(), forKey: "createdAt")
        } else if !blocked, let existing {
            context.delete(existing)
        }
        if context.hasChanges { try context.save() }
        NotificationCenter.default.post(
            name: .kivroBlockStateDidChange,
            object: nil,
            userInfo: ["sourceIdentifier": sourceIdentifier, "targetIdentifier": targetIdentifier]
        )
    }

    func comments(postIdentifier: String) -> [KivroStoredComment] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.comment)
        request.predicate = NSPredicate(format: "postIdentifier == %@", postIdentifier)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? context.fetch(request))?.compactMap(Self.makeStoredComment) ?? []
    }

    func conversationPreviews(for userIdentifier: String) -> [KivroStoredConversationPreview] {
        let messages = chatMessages(involving: userIdentifier)
        var latestByParticipant: [String: KivroStoredChatMessage] = [:]
        for message in messages {
            let participantIdentifier = message.senderIdentifier == userIdentifier
                ? message.recipientIdentifier
                : message.senderIdentifier
            if let current = latestByParticipant[participantIdentifier],
               current.createdAt >= message.createdAt { continue }
            latestByParticipant[participantIdentifier] = message
        }
        return latestByParticipant.compactMap { participantIdentifier, message in
            guard canChat(between: userIdentifier, and: participantIdentifier),
                  let participant = user(identifier: participantIdentifier) else { return nil }
            return KivroStoredConversationPreview(
                user: participant,
                lastMessage: message.body,
                updatedAt: message.createdAt
            )
        }.sorted { $0.updatedAt > $1.updatedAt }
    }

    func chatMessages(between firstUserIdentifier: String, and secondUserIdentifier: String) -> [KivroStoredChatMessage] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.chatMessage)
        request.predicate = NSPredicate(
            format: "(senderIdentifier == %@ AND recipientIdentifier == %@) OR (senderIdentifier == %@ AND recipientIdentifier == %@)",
            firstUserIdentifier,
            secondUserIdentifier,
            secondUserIdentifier,
            firstUserIdentifier
        )
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? chatContext.fetch(request))?.compactMap(Self.makeStoredChatMessage) ?? []
    }

    @discardableResult
    func addChatMessage(
        senderIdentifier: String,
        recipientIdentifier: String,
        body: String
    ) throws -> KivroStoredChatMessage {
        let storedMessage = KivroStoredChatMessage(
            identifier: UUID().uuidString.lowercased(),
            senderIdentifier: senderIdentifier,
            recipientIdentifier: recipientIdentifier,
            body: body,
            contentType: "text",
            mediaData: nil,
            duration: 0,
            createdAt: Date()
        )
        return try persistChatMessage(storedMessage)
    }

    @discardableResult
    func addImageChatMessage(
        senderIdentifier: String,
        recipientIdentifier: String,
        imageData: Data
    ) throws -> KivroStoredChatMessage {
        try persistChatMessage(
            KivroStoredChatMessage(
                identifier: UUID().uuidString.lowercased(),
                senderIdentifier: senderIdentifier,
                recipientIdentifier: recipientIdentifier,
                body: "Photo",
                contentType: "image",
                mediaData: imageData,
                duration: 0,
                createdAt: Date()
            )
        )
    }

    @discardableResult
    func addVoiceChatMessage(
        senderIdentifier: String,
        recipientIdentifier: String,
        audioData: Data,
        duration: TimeInterval
    ) throws -> KivroStoredChatMessage {
        try persistChatMessage(
            KivroStoredChatMessage(
                identifier: UUID().uuidString.lowercased(),
                senderIdentifier: senderIdentifier,
                recipientIdentifier: recipientIdentifier,
                body: "Voice message",
                contentType: "voice",
                mediaData: audioData,
                duration: duration,
                createdAt: Date()
            )
        )
    }

    func addComment(
        postIdentifier: String,
        authorIdentifier: String,
        authorName: String,
        avatarAssetName: String,
        body: String
    ) throws -> KivroStoredComment {
        let comment = NSEntityDescription.insertNewObject(forEntityName: Entity.comment, into: context)
        let identifier = UUID().uuidString.lowercased()
        let createdAt = Date()
        comment.setValue(identifier, forKey: "identifier")
        comment.setValue(postIdentifier, forKey: "postIdentifier")
        comment.setValue(authorIdentifier, forKey: "authorIdentifier")
        comment.setValue(authorName, forKey: "authorName")
        comment.setValue(avatarAssetName, forKey: "avatarAssetName")
        comment.setValue(body, forKey: "body")
        comment.setValue(createdAt, forKey: "createdAt")
        try context.save()
        NotificationCenter.default.post(
            name: .kivroPostEngagementDidChange,
            object: nil,
            userInfo: ["postIdentifier": postIdentifier]
        )
        return KivroStoredComment(
            identifier: identifier,
            postIdentifier: postIdentifier,
            authorIdentifier: authorIdentifier,
            authorName: authorName,
            avatarAssetName: avatarAssetName,
            body: body,
            createdAt: createdAt
        )
    }

    func isPostLiked(postIdentifier: String, userIdentifier: String) -> Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.like)
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "postIdentifier == %@ AND userIdentifier == %@",
            postIdentifier,
            userIdentifier
        )
        return ((try? context.count(for: request)) ?? 0) > 0
    }

    func setPostLiked(
        _ isLiked: Bool,
        postIdentifier: String,
        userIdentifier: String
    ) throws -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.like)
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "postIdentifier == %@ AND userIdentifier == %@",
            postIdentifier,
            userIdentifier
        )
        let existing = try context.fetch(request).first
        if isLiked, existing == nil {
            let like = NSEntityDescription.insertNewObject(forEntityName: Entity.like, into: context)
            like.setValue(UUID().uuidString.lowercased(), forKey: "identifier")
            like.setValue(postIdentifier, forKey: "postIdentifier")
            like.setValue(userIdentifier, forKey: "userIdentifier")
            like.setValue(Date(), forKey: "createdAt")
        } else if !isLiked, let existing {
            context.delete(existing)
        }
        try context.save()
        let count = engagementCounts(postIdentifier: postIdentifier).likes
        NotificationCenter.default.post(
            name: .kivroPostEngagementDidChange,
            object: nil,
            userInfo: ["postIdentifier": postIdentifier]
        )
        return count
    }

    func engagementCounts(postIdentifier: String) -> (likes: Int, comments: Int) {
        let postRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.post)
        postRequest.fetchLimit = 1
        postRequest.predicate = NSPredicate(format: "identifier == %@", postIdentifier)
        let post = (try? context.fetch(postRequest))?.first
        let baseLikes = Int(post?.value(forKey: "likeCount") as? Int64 ?? 0)

        let likeRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.like)
        likeRequest.predicate = NSPredicate(format: "postIdentifier == %@", postIdentifier)
        let addedLikes = (try? context.count(for: likeRequest)) ?? 0

        let commentRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.comment)
        commentRequest.predicate = NSPredicate(format: "postIdentifier == %@", postIdentifier)
        let comments = (try? context.count(for: commentRequest)) ?? 0
        return (baseLikes + addedLikes, comments)
    }

    @discardableResult
    func deleteAccount(userIdentifier: String) throws -> KivroDeletedAccountArtifacts {
        let userRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.user)
        userRequest.fetchLimit = 1
        userRequest.predicate = NSPredicate(format: "identifier == %@", userIdentifier)
        guard let user = try context.fetch(userRequest).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let postRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.post)
        postRequest.predicate = NSPredicate(format: "authorIdentifier == %@", userIdentifier)
        let posts = try context.fetch(postRequest)
        let postIdentifiers = posts.compactMap { $0.value(forKey: "identifier") as? String }
        let mediaPaths = posts.compactMap { $0.value(forKey: "mediaAssetName") as? String }

        let commentRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.comment)
        if postIdentifiers.isEmpty {
            commentRequest.predicate = NSPredicate(format: "authorIdentifier == %@", userIdentifier)
        } else {
            commentRequest.predicate = NSPredicate(
                format: "authorIdentifier == %@ OR postIdentifier IN %@",
                userIdentifier,
                postIdentifiers
            )
        }

        let likeRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.like)
        if postIdentifiers.isEmpty {
            likeRequest.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
        } else {
            likeRequest.predicate = NSPredicate(
                format: "userIdentifier == %@ OR postIdentifier IN %@",
                userIdentifier,
                postIdentifiers
            )
        }

        let followRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.follow)
        followRequest.predicate = NSPredicate(
            format: "sourceIdentifier == %@ OR targetIdentifier == %@",
            userIdentifier,
            userIdentifier
        )

        let blockRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.block)
        blockRequest.predicate = NSPredicate(
            format: "sourceIdentifier == %@ OR targetIdentifier == %@",
            userIdentifier,
            userIdentifier
        )

        let comments = try context.fetch(commentRequest)
        let likes = try context.fetch(likeRequest)
        let follows = try context.fetch(followRequest)
        let blocks = try context.fetch(blockRequest)
        (comments + likes + follows + blocks + posts + [user]).forEach(context.delete)

        let chatRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.chatMessage)
        chatRequest.predicate = NSPredicate(
            format: "senderIdentifier == %@ OR recipientIdentifier == %@",
            userIdentifier,
            userIdentifier
        )
        let chatObjects = try chatContext.fetch(chatRequest)
        let chatBackup = chatObjects.compactMap(Self.makeStoredChatMessage)
        chatObjects.forEach(chatContext.delete)

        do {
            if chatContext.hasChanges { try chatContext.save() }
        } catch {
            chatContext.rollback()
            context.rollback()
            throw error
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            chatBackup.forEach { storedMessage in
                let message = NSEntityDescription.insertNewObject(
                    forEntityName: Entity.chatMessage,
                    into: chatContext
                )
                setChatMessageValues(storedMessage, on: message)
            }
            try? chatContext.save()
            throw error
        }

        NotificationCenter.default.post(name: .kivroPostStoreDidChange, object: nil)
        NotificationCenter.default.post(name: .kivroChatMessagesDidChange, object: nil)
        NotificationCenter.default.post(name: .kivroFollowStateDidChange, object: nil)
        NotificationCenter.default.post(name: .kivroBlockStateDidChange, object: nil)
        return KivroDeletedAccountArtifacts(mediaPaths: mediaPaths)
    }

    private func usersLinkedByRecords(
        entityName: String,
        predicate: NSPredicate,
        userIdentifierKey: String
    ) -> [KivroStoredUser] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return ((try? context.fetch(request)) ?? []).compactMap { record in
            guard let identifier = record.value(forKey: userIdentifierKey) as? String else { return nil }
            return user(identifier: identifier)
        }
    }

    private func seedIfNeeded() throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.user)
        request.fetchLimit = 1
        guard try context.count(for: request) == 0 else { return }
        UserDefaults.standard.removeObject(forKey: Self.socialRelationshipSeedKey)

        let now = Date()
        for (index, record) in Self.seedRecords.enumerated() {
            let user = NSEntityDescription.insertNewObject(forEntityName: Entity.user, into: context)
            user.setValue(record.identifier, forKey: "identifier")
            user.setValue(record.username, forKey: "username")
            user.setValue(record.gender, forKey: "gender")
            user.setValue(record.category, forKey: "category")
            user.setValue(record.avatarAssetName, forKey: "avatarAssetName")
            user.setValue(record.email, forKey: "email")
            user.setValue(Self.seedPassword, forKey: "password")
            user.setValue(record.radarCopy, forKey: "radarCopy")
            user.setValue(record.isRadarProfile, forKey: "isRadarProfile")
            user.setValue(now.addingTimeInterval(TimeInterval(index)), forKey: "createdAt")

            guard let mediaAssetName = record.mediaAssetName,
                  let body = record.body else { continue }
            let post = NSEntityDescription.insertNewObject(forEntityName: Entity.post, into: context)
            let postIdentifier = UUID().uuidString.lowercased()
            post.setValue(postIdentifier, forKey: "identifier")
            post.setValue(record.identifier, forKey: "authorIdentifier")
            post.setValue(record.category, forKey: "category")
            post.setValue(mediaAssetName, forKey: "mediaAssetName")
            post.setValue(body, forKey: "body")
            post.setValue(Int64.random(in: 50...300), forKey: "likeCount")
            post.setValue(mediaAssetName == "ac84882f78d328c470f870e3030639a2_720w", forKey: "isVideo")
            post.setValue(now.addingTimeInterval(TimeInterval(index)), forKey: "createdAt")

            if let commentBody = record.comment {
                let comment = NSEntityDescription.insertNewObject(forEntityName: Entity.comment, into: context)
                comment.setValue(UUID().uuidString.lowercased(), forKey: "identifier")
                comment.setValue(postIdentifier, forKey: "postIdentifier")
                comment.setValue("soren", forKey: "authorIdentifier")
                comment.setValue("Soren", forKey: "authorName")
                comment.setValue("m1", forKey: "avatarAssetName")
                comment.setValue(commentBody, forKey: "body")
                comment.setValue(now.addingTimeInterval(TimeInterval(index) + 0.5), forKey: "createdAt")
            }
        }
        try context.save()
        try seedSocialRelationshipsIfNeeded(now: now)
        try seedChatMessagesIfNeeded(now: now)
        if chatContext.hasChanges { try chatContext.save() }
    }

    private func applyDataCorrections() throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.user)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "identifier == %@", "soren")
        if let soren = try context.fetch(request).first,
           soren.value(forKey: "email") as? String != Self.sorenEmail {
            soren.setValue(Self.sorenEmail, forKey: "email")
        }
        try seedSocialRelationshipsIfNeeded(now: Date())
        try seedChatMessagesIfNeeded(now: Date())
        if context.hasChanges { try context.save() }
        if chatContext.hasChanges { try chatContext.save() }
    }

    private func seedSocialRelationshipsIfNeeded(now: Date) throws {
        guard !UserDefaults.standard.bool(forKey: Self.socialRelationshipSeedKey) else { return }
        let follows = [
            ("soren", "freja"),
            ("freja", "soren"),
            ("soren", "tiernan"),
            ("tiernan", "soren"),
            ("soren", "becker"),
            ("carol", "soren"),
            ("may", "soren"),
            ("thalia", "soren"),
            ("soren", "thalia")
        ]
        for (index, identifiers) in follows.enumerated() {
            guard !isFollowing(
                sourceIdentifier: identifiers.0,
                targetIdentifier: identifiers.1
            ) else { continue }
            let record = NSEntityDescription.insertNewObject(forEntityName: Entity.follow, into: context)
            record.setValue(UUID().uuidString.lowercased(), forKey: "identifier")
            record.setValue(identifiers.0, forKey: "sourceIdentifier")
            record.setValue(identifiers.1, forKey: "targetIdentifier")
            record.setValue(now.addingTimeInterval(TimeInterval(index)), forKey: "createdAt")
        }

        let blockRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.block)
        blockRequest.fetchLimit = 1
        blockRequest.predicate = NSPredicate(
            format: "sourceIdentifier == %@ AND targetIdentifier == %@",
            "soren",
            "kasper"
        )
        if try context.fetch(blockRequest).isEmpty {
            let record = NSEntityDescription.insertNewObject(forEntityName: Entity.block, into: context)
            record.setValue(UUID().uuidString.lowercased(), forKey: "identifier")
            record.setValue("soren", forKey: "sourceIdentifier")
            record.setValue("kasper", forKey: "targetIdentifier")
            record.setValue(now.addingTimeInterval(TimeInterval(follows.count)), forKey: "createdAt")
        }
        if context.hasChanges { try context.save() }
        UserDefaults.standard.set(true, forKey: Self.socialRelationshipSeedKey)
    }

    private func seedChatMessagesIfNeeded(now: Date) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.chatMessage)
        request.fetchLimit = 1
        guard try chatContext.count(for: request) == 0 else { return }

        let lastMessageDates = (0..<3).map { _ in
            now.addingTimeInterval(-TimeInterval.random(in: 60...86_400))
        }
        let conversations: [[KivroStoredChatMessage]] = [
            [
                .init(
                    identifier: UUID().uuidString.lowercased(),
                    senderIdentifier: "freja",
                    recipientIdentifier: "soren",
                    body: "Your Gothic armor build looks incredible.",
                    contentType: "text",
                    mediaData: nil,
                    duration: 0,
                    createdAt: lastMessageDates[0].addingTimeInterval(-120)
                ),
                .init(
                    identifier: UUID().uuidString.lowercased(),
                    senderIdentifier: "soren",
                    recipientIdentifier: "freja",
                    body: "Thank you! I am finishing the last foam details tonight.",
                    contentType: "text",
                    mediaData: nil,
                    duration: 0,
                    createdAt: lastMessageDates[0].addingTimeInterval(-60)
                ),
                .init(
                    identifier: UUID().uuidString.lowercased(),
                    senderIdentifier: "freja",
                    recipientIdentifier: "soren",
                    body: "Send me a photo when it is ready!",
                    contentType: "text",
                    mediaData: nil,
                    duration: 0,
                    createdAt: lastMessageDates[0]
                )
            ],
            [
                .init(
                    identifier: UUID().uuidString.lowercased(),
                    senderIdentifier: "tiernan",
                    recipientIdentifier: "soren",
                    body: "Do you have a recommendation for painting armor edges?",
                    contentType: "text",
                    mediaData: nil,
                    duration: 0,
                    createdAt: lastMessageDates[1].addingTimeInterval(-60)
                ),
                .init(
                    identifier: UUID().uuidString.lowercased(),
                    senderIdentifier: "soren",
                    recipientIdentifier: "tiernan",
                    body: "Try a dry brush with silver acrylic for a worn metal effect.",
                    contentType: "text",
                    mediaData: nil,
                    duration: 0,
                    createdAt: lastMessageDates[1]
                )
            ],
            [
                .init(
                    identifier: UUID().uuidString.lowercased(),
                    senderIdentifier: "thalia",
                    recipientIdentifier: "soren",
                    body: "Which neon color would fit my visor best?",
                    contentType: "text",
                    mediaData: nil,
                    duration: 0,
                    createdAt: lastMessageDates[2].addingTimeInterval(-120)
                ),
                .init(
                    identifier: UUID().uuidString.lowercased(),
                    senderIdentifier: "soren",
                    recipientIdentifier: "thalia",
                    body: "Violet would look great with the darker costume panels.",
                    contentType: "text",
                    mediaData: nil,
                    duration: 0,
                    createdAt: lastMessageDates[2].addingTimeInterval(-60)
                ),
                .init(
                    identifier: UUID().uuidString.lowercased(),
                    senderIdentifier: "thalia",
                    recipientIdentifier: "soren",
                    body: "Violet it is. Thanks!",
                    contentType: "text",
                    mediaData: nil,
                    duration: 0,
                    createdAt: lastMessageDates[2]
                )
            ]
        ]
        conversations.joined().forEach { storedMessage in
            let message = NSEntityDescription.insertNewObject(forEntityName: Entity.chatMessage, into: chatContext)
            setChatMessageValues(storedMessage, on: message)
        }
    }

    private func chatMessages(involving userIdentifier: String) -> [KivroStoredChatMessage] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.chatMessage)
        request.predicate = NSPredicate(
            format: "senderIdentifier == %@ OR recipientIdentifier == %@",
            userIdentifier,
            userIdentifier
        )
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? chatContext.fetch(request))?.compactMap(Self.makeStoredChatMessage) ?? []
    }

    private func setChatMessageValues(_ storedMessage: KivroStoredChatMessage, on object: NSManagedObject) {
        object.setValue(storedMessage.identifier, forKey: "identifier")
        object.setValue(storedMessage.senderIdentifier, forKey: "senderIdentifier")
        object.setValue(storedMessage.recipientIdentifier, forKey: "recipientIdentifier")
        object.setValue(storedMessage.body, forKey: "body")
        object.setValue(storedMessage.contentType, forKey: "contentType")
        object.setValue(storedMessage.mediaData, forKey: "mediaData")
        object.setValue(storedMessage.duration, forKey: "duration")
        object.setValue(storedMessage.createdAt, forKey: "createdAt")
    }

    private func persistChatMessage(_ storedMessage: KivroStoredChatMessage) throws -> KivroStoredChatMessage {
        guard canChat(
            between: storedMessage.senderIdentifier,
            and: storedMessage.recipientIdentifier
        ) else {
            throw NSError(
                domain: "KivroChat",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mutual following is required."]
            )
        }
        let message = NSEntityDescription.insertNewObject(forEntityName: Entity.chatMessage, into: chatContext)
        setChatMessageValues(storedMessage, on: message)
        try chatContext.save()
        NotificationCenter.default.post(name: .kivroChatMessagesDidChange, object: nil)
        return storedMessage
    }

    nonisolated private static func makeStoredUser(_ object: NSManagedObject) -> KivroStoredUser? {
        guard let identifier = object.value(forKey: "identifier") as? String,
              let username = object.value(forKey: "username") as? String,
              let gender = object.value(forKey: "gender") as? String,
              let category = object.value(forKey: "category") as? String,
              let avatarAssetName = object.value(forKey: "avatarAssetName") as? String,
              let email = object.value(forKey: "email") as? String,
              let password = object.value(forKey: "password") as? String else { return nil }
        return KivroStoredUser(
            identifier: identifier,
            username: username,
            gender: gender,
            category: category,
            avatarAssetName: avatarAssetName,
            email: email,
            password: password,
            radarCopy: object.value(forKey: "radarCopy") as? String,
            isRadarProfile: object.value(forKey: "isRadarProfile") as? Bool ?? false,
            birthday: object.value(forKey: "birthday") as? Date,
            countryCode: object.value(forKey: "countryCode") as? String
        )
    }

    nonisolated private static func makeStoredPost(_ object: NSManagedObject) -> KivroStoredPost? {
        guard let identifier = object.value(forKey: "identifier") as? String,
              let authorIdentifier = object.value(forKey: "authorIdentifier") as? String,
              let category = object.value(forKey: "category") as? String,
              let mediaAssetName = object.value(forKey: "mediaAssetName") as? String,
              let body = object.value(forKey: "body") as? String else { return nil }
        let engagement = engagementCountsForStoredPost(object)
        return KivroStoredPost(
            identifier: identifier,
            authorIdentifier: authorIdentifier,
            category: category,
            mediaAssetName: mediaAssetName,
            body: body,
            likeCount: engagement.likes,
            commentCount: engagement.comments,
            isVideo: object.value(forKey: "isVideo") as? Bool ?? false
        )
    }

    nonisolated private static func makeStoredComment(_ object: NSManagedObject) -> KivroStoredComment? {
        guard let identifier = object.value(forKey: "identifier") as? String,
              let postIdentifier = object.value(forKey: "postIdentifier") as? String,
              let authorIdentifier = object.value(forKey: "authorIdentifier") as? String,
              let authorName = object.value(forKey: "authorName") as? String,
              let avatarAssetName = object.value(forKey: "avatarAssetName") as? String,
              let body = object.value(forKey: "body") as? String,
              let createdAt = object.value(forKey: "createdAt") as? Date else { return nil }
        return KivroStoredComment(
            identifier: identifier,
            postIdentifier: postIdentifier,
            authorIdentifier: authorIdentifier,
            authorName: authorName,
            avatarAssetName: avatarAssetName,
            body: body,
            createdAt: createdAt
        )
    }

    nonisolated private static func makeStoredChatMessage(_ object: NSManagedObject) -> KivroStoredChatMessage? {
        guard let identifier = object.value(forKey: "identifier") as? String,
              let senderIdentifier = object.value(forKey: "senderIdentifier") as? String,
              let recipientIdentifier = object.value(forKey: "recipientIdentifier") as? String,
              let body = object.value(forKey: "body") as? String,
              let createdAt = object.value(forKey: "createdAt") as? Date else { return nil }
        return KivroStoredChatMessage(
            identifier: identifier,
            senderIdentifier: senderIdentifier,
            recipientIdentifier: recipientIdentifier,
            body: body,
            contentType: object.value(forKey: "contentType") as? String ?? "text",
            mediaData: object.value(forKey: "mediaData") as? Data,
            duration: object.value(forKey: "duration") as? TimeInterval ?? 0,
            createdAt: createdAt
        )
    }

    nonisolated private static func engagementCountsForStoredPost(
        _ object: NSManagedObject
    ) -> (likes: Int, comments: Int) {
        guard let context = object.managedObjectContext,
              let postIdentifier = object.value(forKey: "identifier") as? String else { return (0, 0) }
        let baseLikes = Int(object.value(forKey: "likeCount") as? Int64 ?? 0)
        let likeRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.like)
        likeRequest.predicate = NSPredicate(format: "postIdentifier == %@", postIdentifier)
        let commentRequest = NSFetchRequest<NSManagedObject>(entityName: Entity.comment)
        commentRequest.predicate = NSPredicate(format: "postIdentifier == %@", postIdentifier)
        return (
            baseLikes + ((try? context.count(for: likeRequest)) ?? 0),
            (try? context.count(for: commentRequest)) ?? 0
        )
    }

    private static func makeStoreURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Kivro", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("Kivro.sqlite")
    }

    private static func makeChatStoreURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Kivro", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("KivroChat.sqlite")
    }

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let user = NSEntityDescription()
        user.name = Entity.user
        user.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        user.properties = [
            attribute("identifier", type: .stringAttributeType),
            attribute("username", type: .stringAttributeType),
            attribute("gender", type: .stringAttributeType),
            attribute("category", type: .stringAttributeType),
            attribute("avatarAssetName", type: .stringAttributeType),
            attribute("email", type: .stringAttributeType),
            attribute("password", type: .stringAttributeType),
            attribute("radarCopy", type: .stringAttributeType, optional: true),
            attribute("isRadarProfile", type: .booleanAttributeType, defaultValue: false),
            attribute("birthday", type: .dateAttributeType, optional: true),
            attribute("countryCode", type: .stringAttributeType, optional: true),
            attribute("createdAt", type: .dateAttributeType)
        ]
        user.uniquenessConstraints = [["identifier"], ["email"]]

        let post = NSEntityDescription()
        post.name = Entity.post
        post.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        post.properties = [
            attribute("identifier", type: .stringAttributeType),
            attribute("authorIdentifier", type: .stringAttributeType),
            attribute("category", type: .stringAttributeType),
            attribute("mediaAssetName", type: .stringAttributeType),
            attribute("body", type: .stringAttributeType),
            attribute("likeCount", type: .integer64AttributeType, defaultValue: Int64(0)),
            attribute("isVideo", type: .booleanAttributeType, defaultValue: false),
            attribute("createdAt", type: .dateAttributeType)
        ]
        post.uniquenessConstraints = [["identifier"]]

        let comment = NSEntityDescription()
        comment.name = Entity.comment
        comment.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        comment.properties = [
            attribute("identifier", type: .stringAttributeType),
            attribute("postIdentifier", type: .stringAttributeType),
            attribute("authorIdentifier", type: .stringAttributeType),
            attribute("authorName", type: .stringAttributeType),
            attribute("avatarAssetName", type: .stringAttributeType),
            attribute("body", type: .stringAttributeType),
            attribute("createdAt", type: .dateAttributeType)
        ]
        comment.uniquenessConstraints = [["identifier"]]

        let like = NSEntityDescription()
        like.name = Entity.like
        like.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        like.properties = [
            attribute("identifier", type: .stringAttributeType),
            attribute("postIdentifier", type: .stringAttributeType),
            attribute("userIdentifier", type: .stringAttributeType),
            attribute("createdAt", type: .dateAttributeType)
        ]
        like.uniquenessConstraints = [["identifier"], ["postIdentifier", "userIdentifier"]]

        let follow = NSEntityDescription()
        follow.name = Entity.follow
        follow.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        follow.properties = [
            attribute("identifier", type: .stringAttributeType),
            attribute("sourceIdentifier", type: .stringAttributeType),
            attribute("targetIdentifier", type: .stringAttributeType),
            attribute("createdAt", type: .dateAttributeType)
        ]
        follow.uniquenessConstraints = [["identifier"], ["sourceIdentifier", "targetIdentifier"]]

        let block = NSEntityDescription()
        block.name = Entity.block
        block.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        block.properties = [
            attribute("identifier", type: .stringAttributeType),
            attribute("sourceIdentifier", type: .stringAttributeType),
            attribute("targetIdentifier", type: .stringAttributeType),
            attribute("createdAt", type: .dateAttributeType)
        ]
        block.uniquenessConstraints = [["identifier"], ["sourceIdentifier", "targetIdentifier"]]

        model.entities = [user, post, comment, like, follow, block]
        return model
    }

    private static func makeChatManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let chatMessage = NSEntityDescription()
        chatMessage.name = Entity.chatMessage
        chatMessage.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        chatMessage.properties = [
            attribute("identifier", type: .stringAttributeType),
            attribute("senderIdentifier", type: .stringAttributeType),
            attribute("recipientIdentifier", type: .stringAttributeType),
            attribute("body", type: .stringAttributeType),
            attribute("contentType", type: .stringAttributeType, defaultValue: "text"),
            attribute("mediaData", type: .binaryDataAttributeType, optional: true),
            attribute("duration", type: .doubleAttributeType, defaultValue: 0.0),
            attribute("createdAt", type: .dateAttributeType)
        ]
        chatMessage.uniquenessConstraints = [["identifier"]]
        model.entities = [chatMessage]
        return model
    }

    private static func attribute(
        _ name: String,
        type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let property = NSAttributeDescription()
        property.name = name
        property.attributeType = type
        property.isOptional = optional
        property.defaultValue = defaultValue
        return property
    }
}
