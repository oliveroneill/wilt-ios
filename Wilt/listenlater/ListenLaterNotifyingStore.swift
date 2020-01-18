/// A wrapper around a dao for accessing the "listen later" database, for adding notifications to be triggered
/// for new items.
final class ListenLaterNotifyingStore: ListenLaterDao {
    private let dao: ListenLaterDao
    private let notificationCenter = UNUserNotificationCenter.current()

    var onDataChange: (() -> Void)? {
        didSet {
            dao.onDataChange = onDataChange
        }
    }

    var items: [ListenLaterArtist] {
        dao.items
    }

    init(dao: ListenLaterDao) {
        self.dao = dao
    }

    func insert(item: ListenLaterArtist) throws {
        try dao.insert(item: item)
        addNotification(for: item.name)
    }

    private func addNotification(for name: String) {
        let content = UNMutableNotificationContent()
        // Random select the notification title, so the app doesn't sound
        // repetitive
        let titleIndex = Int.random(in: 0 ..< 4)
        content.title = String(
            format: "notification_title_\(titleIndex)".localized,
            name
        )
        content.body = "notification_subtitle".localized
        // Trigger one week from now to remind the user
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 60 * 60 * 24 * 7,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: name,
            content: content,
            trigger: trigger
        )
        // It doesn't necessarily matter if the notification scheduling fails
        // so we don't need to check the error
        notificationCenter.add(request)
    }

    func contains(name: String) throws -> Bool {
        try dao.contains(name: name)
    }

    func delete(name: String) throws {
        try dao.delete(name: name)
        // Delete the scheduled notification
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [name]
        )
    }
}
