import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        )) ?? false
    }

    func schedule(for item: TravelItem, tripTitle: String) {
        guard item.notify, item.date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = tripTitle
        content.body = item.title
        content.sound = .default

        let alertDate = Calendar.current.date(
            byAdding: .hour,
            value: -2,
            to: item.date
        ) ?? item.date

        guard alertDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: alertDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
