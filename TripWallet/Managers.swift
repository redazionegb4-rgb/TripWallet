import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        )) ?? false
    }

    func schedule(booking: Booking, tripTitle: String) {
        guard booking.reminderEnabled, booking.startDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = tripTitle
        content.body = "\(booking.type.rawValue): \(booking.title)"
        content.sound = .default

        let reminderDate = Calendar.current.date(
            byAdding: .hour,
            value: -2,
            to: booking.startDate
        ) ?? booking.startDate

        guard reminderDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: booking.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
