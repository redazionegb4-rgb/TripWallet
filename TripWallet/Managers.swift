import Foundation
import UserNotifications
import LocalAuthentication

final class NotificationManager {
    static let shared = NotificationManager()
    func requestAuthorization() async { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) }
    func schedule(for item: TravelItem, tripTitle: String) {
        guard item.notify, item.date > Date() else { return }
        let content = UNMutableNotificationContent(); content.title = tripTitle; content.body = item.title; content.sound = .default
        let triggerDate = Calendar.current.date(byAdding: .hour, value: -2, to: item.date) ?? item.date
        guard triggerDate > Date() else { return }
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: triggerDate), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger))
    }
    func cancel(_ id: UUID) { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString]) }
}

@MainActor
final class BiometricManager {
    static func authenticate() async -> Bool {
        let context = LAContext(); var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Sblocca TripWallet")) ?? false
    }
}
