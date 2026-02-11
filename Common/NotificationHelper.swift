import Foundation
import UserNotifications

private var logger = AccuChekLogger(category: "NotificationHelper")

struct NotificationContent {
    let identifier: String
    let title: String
    let content: String
}

enum NotificationHelper {
    public static func sendCgmAlert(alerts: [NotificationContent]) {
        ensureCanSendNotification {
            alerts.forEach {
                let content = UNMutableNotificationContent()
                content.title = $0.title
                content.body = $0.content

                addRequest(identifier: $0.identifier, content: content)
            }
        }
    }

    public static func clearNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(
            withIdentifiers: SensorStatusEnum.allCases.compactMap { $0.notification?.identifier }
        )
    }

    private static func addRequest(
        identifier: String,
        content: UNMutableNotificationContent,
        triggerAfter: TimeInterval? = nil,
        deleteOld: Bool = false
    ) {
        let center = UNUserNotificationCenter.current()
        var trigger: UNCalendarNotificationTrigger?

        if deleteOld {
            // Required since ios12+ have started to cache/group notifications
            center.removeDeliveredNotifications(withIdentifiers: [identifier])
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
        }

        if let triggerAfter = triggerAfter {
            let notifTime = Date.now.addingTimeInterval(triggerAfter)
            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: notifTime)

            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        }

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                logger.info("unable to addNotificationRequest: \(error.localizedDescription)")
                return
            }

            logger.info("sending \(identifier) notification")
        }
    }

    private static func ensureCanSendNotification(_ completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                logger.info("ensureCanSendNotification failed, authorization denied")
                return
            }

            logger.info("sending notification was allowed")

            completion()
        }
    }
}
