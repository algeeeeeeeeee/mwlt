import Foundation
import UserNotifications

@MainActor
enum RecurringTransactionAutomation {
    private static let processedDateKey = "gm_recurring_last_processed_date"

    static func processDueItems(store: FinanceStore) {
        let defaults = UserDefaults.standard
        let now = Date.now
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: now)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.calendar = calendar
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = dateFormatter.string(from: now)

        // Process once per local calendar day to prevent repeat entries and reminders.
        guard defaults.string(forKey: processedDateKey) != todayKey else { return }

        let raw = defaults.string(forKey: "gm_recurring") ?? "[]"
        guard let data = raw.data(using: .utf8),
              let items = try? JSONDecoder().decode([NativeRecurringItem].self, from: data) else {
            defaults.set(todayKey, forKey: processedDateKey)
            return
        }

        let notificationsEnabled = defaults.string(forKey: "gm_notif") == "1"
        let isEnglish = defaults.string(forKey: "gm_lang") == "en"

        for item in items where item.day == dayOfMonth {
            guard item.amount > 0,
                  !item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

            if item.autoApply {
                let alreadyAdded = store.transactions.contains {
                    calendar.isDate($0.date, inSameDayAs: now) &&
                    $0.description == item.description &&
                    $0.amount == item.amount &&
                    $0.location == "Rutin"
                }
                guard !alreadyAdded else { continue }

                store.add(MeowlettTransaction(
                    date: now,
                    amount: item.amount,
                    category: item.category,
                    description: item.description,
                    location: "Rutin",
                    note: "Otomatis"
                ))

                if notificationsEnabled {
                    postNotification(
                        title: isEnglish ? "Auto-recorded" : "Tercatat Otomatis",
                        body: isEnglish
                            ? "\(item.description) — \(rupiah(item.amount)) recorded"
                            : "\(item.description) — \(rupiah(item.amount)) dicatat"
                    )
                }
            } else if notificationsEnabled {
                postNotification(
                    title: isEnglish ? "Payment reminder" : "Pengingat Tagihan",
                    body: isEnglish
                        ? "Time to record: \(item.description) — \(rupiah(item.amount))"
                        : "Waktunya catat: \(item.description) — \(rupiah(item.amount))"
                )
            }
        }

        defaults.set(todayKey, forKey: processedDateKey)
    }

    private static func rupiah(_ amount: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "Rp \(amount)"
    }

    private static func postNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "meowlett-recurring-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}