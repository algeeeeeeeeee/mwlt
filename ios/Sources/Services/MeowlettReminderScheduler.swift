import Foundation
import UserNotifications

@MainActor
enum MeowlettReminderScheduler {
    private static let identifierPrefix = "meowlett-reminder-"

    static func schedule(
        days: [Int],
        hour: Int,
        smart: Bool,
        language: String,
        transactions: [MeowlettTransaction]
    ) {
        removePendingRequests()
        guard !days.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)
        let content = UNMutableNotificationContent()
        content.title = "Meowlett"
        content.body = language == "en"
            ? "💸 Haven't logged expenses today! Don't forget to record your transactions 🐱"
            : "💸 Belum catat pengeluaran hari ini! Jangan lupa input transaksi 🐱"
        content.sound = .default

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"

        for offset in 0..<14 {
            guard let dayDate = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: dayDate) - 1
            guard days.contains(weekday) else { continue }
            if smart && transactions.contains(where: { calendar.isDate($0.date, inSameDayAs: dayDate) }) {
                continue
            }
            guard let fireDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: dayDate),
                  fireDate > now else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: dayDate)
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            components.hour = hour
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = identifierPrefix + formatter.string(from: dayDate)
            center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }

    static func scheduleFromDefaults(transactions: [MeowlettTransaction]) {
        let defaults = UserDefaults.standard
        // Disabling notifications already removes pending requests from Settings.
        // Avoid a UserNotifications IPC call on every transaction change while off.
        guard defaults.string(forKey: "gm_notif") == "1" else { return }
        let daysRaw = defaults.string(forKey: "gm_reminder_days") ?? "[1,2,3,4,5]"
        let days = (try? JSONDecoder().decode([Int].self, from: Data(daysRaw.utf8))) ?? [1,2,3,4,5]
        let hour = Int(defaults.string(forKey: "gm_reminder_hour") ?? "21") ?? 21
        let smart = defaults.string(forKey: "gm_reminder_smart") != "0"
        let language = defaults.string(forKey: "gm_lang") ?? "id"
        schedule(days: days, hour: min(23, max(0, hour)), smart: smart, language: language, transactions: transactions)
    }

    static func removePendingRequests() {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        var identifiers = (0..<7).map { identifierPrefix + String($0) }
        for offset in -35...35 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: .now) else { continue }
            identifiers.append(identifierPrefix + formatter.string(from: date))
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
