import SwiftUI
import UserNotifications

struct SettingsReminderSheet: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_notif") private var notificationEnabled = "0"
    @AppStorage("gm_reminder_hour") private var reminderHour = "21"
    @AppStorage("gm_reminder_days") private var reminderDaysRaw = "[1,2,3,4,5]"
    @AppStorage("gm_reminder_smart") private var reminderSmart = "1"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var financeStore: FinanceStore
    @State private var reminderDays = [1,2,3,4,5]
    @State private var loaded = false
    @State private var permissionMessage: String?
    @State private var isRequestingPermission = false

    private var isEnglish: Bool { language == "en" }
    private var isDark: Bool { colorScheme == .dark }
    private var accent: Color { AppAppearance.accent }
    private var primary: Color { AppAppearance.primary }
    private var categoryBackground: Color {
        isDark ? AppAppearance.card2(dark: true) : AppAppearance.background(dark: false)
    }
    private var hour: Int { min(23, max(0, Int(reminderHour) ?? 21)) }
    private var dayLabels: [String] {
        isEnglish ? ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"] : ["Min","Sen","Sel","Rab","Kam","Jum","Sab"]
    }
    private var timeLabel: String { String(format: "%02d:00", hour) }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppAppearance.border(dark: isDark))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            HStack(spacing: 9) {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(accent)
                Text(isEnglish ? "Transaction Reminder" : "Pengingat Transaksi")
                    .font(MeowlettTypography.font(size: 16, weight: .black))
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("mwlt.settings.reminder.title")
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppAppearance.textSub(dark: isDark))
                        .frame(width: 30, height: 30)
                        .background(categoryBackground, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .overlay(alignment: .bottom) {
                Rectangle().fill(AppAppearance.border(dark: isDark)).frame(height: 1)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroCard
                    pushNotificationsRow

                    Divider().overlay(AppAppearance.border(dark: isDark))

                    reminderTimeRow

                    Divider().overlay(AppAppearance.border(dark: isDark))

                    activeDaysSection

                    Divider().overlay(AppAppearance.border(dark: isDark))

                    smartReminderRow

                    notificationPreview

                    Button {
                        saveDays()
                        if notificationEnabled == "1" { scheduleNotifications() }
                        dismiss()
                    } label: {
                        Text(isEnglish ? "Save Settings" : "Simpan Pengaturan")
                            .font(MeowlettTypography.font(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)                    .buttonStyle(.plain)
                    .accessibilityIdentifier("mwlt.settings.reminder.save")
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(AppAppearance.modal(dark: isDark))
        .alert(
            isEnglish ? "Notifications unavailable" : "Notifikasi tidak tersedia",
            isPresented: Binding(
                get: { permissionMessage != nil },
                set: { if !$0 { permissionMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { permissionMessage = nil }
        } message: {
            Text(permissionMessage ?? "")
        }
        .presentationDetents([.fraction(0.9)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
        .onAppear {
            guard !loaded else { return }
            if let data = reminderDaysRaw.data(using: .utf8),
               let decoded = try? JSONDecoder().decode([Int].self, from: data) {
                reminderDays = decoded.filter { (0...6).contains($0) }.sorted()
            }
            loaded = true
        }
        .onChange(of: reminderDays) { _, _ in
            saveDays()
            if notificationEnabled == "1" { scheduleNotifications() }
        }
        .onChange(of: reminderHour) { _, _ in
            if notificationEnabled == "1" { scheduleNotifications() }
        }
        .onChange(of: reminderSmart) { _, _ in
            if notificationEnabled == "1" { scheduleNotifications() }
        }
    }

    private var heroCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "bell")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(isEnglish ? "Transaction Reminder" : "Pengingat Transaksi")
                    .font(MeowlettTypography.font(size: 14, weight: .heavy))
                    .foregroundStyle(.primary)
                Text(isEnglish
                     ? "Notify if no spending recorded today"
                     : "Notif kalau belum input pengeluaran hari ini")
                    .font(MeowlettTypography.font(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            LinearGradient(colors: [accent.opacity(0.09), primary.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.15), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 0)
    }

    private var pushNotificationsRow: some View {
        Button {
            Task { await setNotifications(notificationEnabled != "1") }
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryBackground)
                    .frame(width: 38, height: 38)
                    .overlay(Image(systemName: "bell")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(notificationEnabled == "1" ? accent : AppAppearance.textSub(dark: isDark)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(isEnglish ? "Push Notifications" : "Notifikasi")
                        .font(MeowlettTypography.font(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(notificationEnabled == "1"
                         ? (isEnglish ? "Active — every day at 9 PM" : "Aktif — setiap hari jam 9 malam")
                         : (isEnglish ? "Inactive" : "Nonaktif"))
                        .font(MeowlettTypography.font(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                reminderSwitch(isOn: notificationEnabled == "1", isLoading: isRequestingPermission)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isRequestingPermission)
    }

    private var reminderTimeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(isEnglish ? "Reminder Time" : "Waktu Pengingat")
                    .font(MeowlettTypography.font(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Text(isEnglish ? "Notification sent at" : "Notif dikirim jam")
                    .font(MeowlettTypography.font(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                ForEach([6,7,8,9,10,12,15,18,19,20,21,22], id: \.self) { value in
                    Button(String(format: "%02d:00", value)) {
                        reminderHour = String(value)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(timeLabel)
                        .font(MeowlettTypography.font(size: 16, weight: .black))
                        .foregroundStyle(accent)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(categoryBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppAppearance.border(dark: isDark), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var activeDaysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isEnglish ? "Active Days" : "Hari Aktif")
                .font(MeowlettTypography.font(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    let selected = reminderDays.contains(index)
                    Button {
                        if selected {
                            reminderDays.removeAll { $0 == index }
                        } else {
                            reminderDays.append(index)
                            reminderDays.sort()
                        }
                    } label: {
                        Text(dayLabels[index])
                            .font(MeowlettTypography.font(size: 11, weight: .heavy))
                            .foregroundStyle(selected ? accent : AppAppearance.textSub(dark: isDark))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(selected ? accent.opacity(0.13) : categoryBackground, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selected ? accent.opacity(0.31) : AppAppearance.border(dark: isDark), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var smartReminderRow: some View {
        Button {
            reminderSmart = reminderSmart == "0" ? "1" : "0"
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryBackground)
                    .frame(width: 38, height: 38)
                    .overlay(Image(systemName: "bell")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(AppAppearance.textSub(dark: isDark)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(isEnglish ? "Smart Reminder" : "Pengingat Cerdas")
                        .font(MeowlettTypography.font(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(isEnglish
                         ? "Skip if transaction already recorded today"
                         : "Lewati kalau sudah ada transaksi hari ini")
                        .font(MeowlettTypography.font(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                reminderSwitch(isOn: reminderSmart != "0")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var notificationPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isEnglish ? "NOTIFICATION PREVIEW" : "PRATINJAU NOTIFIKASI")
                .font(MeowlettTypography.font(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text("🐱")
                        .font(MeowlettTypography.font(size: 14, weight: .regular))
                        .frame(width: 28, height: 28)
                        .background(
                            LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    Text("Meowlett")
                        .font(MeowlettTypography.font(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(timeLabel)
                        .font(MeowlettTypography.font(size: 11, weight: .regular))
                        .foregroundStyle(Color.secondary)
                }
                Text(isEnglish ? "🐾 No spending recorded today!" : "🐾 Belum catat pengeluaran hari ini!")
                    .font(MeowlettTypography.font(size: 13, weight: .heavy))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 3)
                Text(isEnglish
                     ? "Don't forget to log transactions to stay on track 🐱"
                     : "Jangan lupa input transaksi biar keuanganmu tetap terkontrol 🐱")
                    .font(MeowlettTypography.font(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(categoryBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppAppearance.border(dark: isDark), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private func reminderSwitch(isOn: Bool, isLoading: Bool = false) -> some View {
        Capsule()
            .fill(categoryBackground)
            .overlay {
                if isOn {
                    Capsule().fill(LinearGradient(colors: [accent, primary], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .frame(width: 46, height: 26)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 1)
                    .padding(3)
            }
            .overlay(Capsule().stroke(isOn ? Color.clear : AppAppearance.border(dark: isDark), lineWidth: 1.5))
            .opacity(isLoading ? 0.55 : 1)
            .animation(.easeInOut(duration: 0.18), value: isOn)
    }

    @MainActor
    private func setNotifications(_ value: Bool) async {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        defer { isRequestingPermission = false }

        guard value else {
            notificationEnabled = "0"
            MeowlettReminderScheduler.removePendingRequests()
            return
        }

        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                notificationEnabled = "0"
                permissionMessage = isEnglish
                    ? "Notification permission was denied. Enable it in iPhone Settings."
                    : "Izin notifikasi ditolak. Aktifkan melalui Pengaturan iPhone."
                return
            }

            notificationEnabled = "1"
            scheduleNotifications()

            let confirmation = UNMutableNotificationContent()
            confirmation.title = "Meowlett"
            confirmation.body = isEnglish
                ? "Reminder on! You'll be notified every day at 9 PM."
                : "Pengingat aktif! Kamu akan diingatkan setiap hari jam 9 malam."
            confirmation.sound = .default
            let request = UNNotificationRequest(
                identifier: "meowlett-reminder-activated",
                content: confirmation,
                trigger: nil
            )
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            notificationEnabled = "0"
            MeowlettReminderScheduler.removePendingRequests()
            permissionMessage = error.localizedDescription
        }
    }

    private func saveDays() {
        guard loaded,
              let data = try? JSONEncoder().encode(reminderDays),
              let json = String(data: data, encoding: .utf8) else { return }
        reminderDaysRaw = json
    }

    @MainActor
    private func scheduleNotifications() {
        MeowlettReminderScheduler.schedule(
            days: reminderDays,
            hour: hour,
            smart: reminderSmart != "0",
            language: language,
            transactions: financeStore.transactions
        )
    }
}

private struct NativeInstallment: Codable, Identifiable, Equatable {
    var id: Int64
    var name: String
    var total: Int64
    var monthly: Int64
    var dueDay: String
    var startMonth: String
    var duration: Int
    var paidMonths: [String]

    init(id: Int64, name: String, total: Int64, monthly: Int64, dueDay: String, startMonth: String, duration: Int, paidMonths: [String]) {
        self.id = id
        self.name = name
        self.total = total
        self.monthly = monthly
        self.dueDay = dueDay
        self.startMonth = startMonth
        self.duration = duration
        self.paidMonths = paidMonths
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, total, monthly, dueDay, startMonth, duration, paidMonths
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? values.decode(Int64.self, forKey: .id) {
            id = value
        } else if let value = try? values.decode(Double.self, forKey: .id) {
            id = Int64(value)
        } else {
            id = Int64(Date().timeIntervalSince1970 * 1000)
        }
        name = (try? values.decode(String.self, forKey: .name)) ?? ""
        total = (try? values.decode(Int64.self, forKey: .total))
            ?? Int64((try? values.decode(String.self, forKey: .total))?.filter(\.isNumber) ?? "") ?? 0
        monthly = (try? values.decode(Int64.self, forKey: .monthly))
            ?? Int64((try? values.decode(String.self, forKey: .monthly))?.filter(\.isNumber) ?? "") ?? 0
        dueDay = (try? values.decode(String.self, forKey: .dueDay))
            ?? String((try? values.decode(Int.self, forKey: .dueDay)) ?? 5)
        startMonth = (try? values.decode(String.self, forKey: .startMonth))
            ?? Date.now.formatted(.dateTime.year().month(.twoDigits))
        duration = (try? values.decode(Int.self, forKey: .duration))
            ?? Int((try? values.decode(String.self, forKey: .duration)) ?? "") ?? 12
        paidMonths = (try? values.decode([String].self, forKey: .paidMonths)) ?? []
    }
}

struct SettingsCicilanSheet: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_cicilan") private var cicilanRaw = "[]"
    @State private var items: [NativeInstallment] = []
    @State private var loaded = false
    @State private var editorItem: NativeInstallment?
    @State private var detailID: Int64?
    @Environment(\.dismiss) private var dismiss

    private var isEnglish: Bool { language == "en" }
    private var currentMonth: String { Date.now.formatted(.dateTime.year().month(.twoDigits)) }
    private var totalMonthly: Int64 { items.reduce(0) { $0 + $1.monthly } }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 36, height: 4).padding(.top, 12)
            HStack {
                Label(isEnglish ? "Installments" : "Cicilan", systemImage: "creditcard")
                    .font(.system(size: 16, weight: .black)).foregroundStyle(.primary)
                    .accessibilityIdentifier("mwlt.transactions.installments.title")
                Spacer()
                Button {
                    editorItem = NativeInstallment(id: Int64(Date().timeIntervalSince1970 * 1000), name: "", total: 0, monthly: 0, dueDay: "5", startMonth: currentMonth, duration: 12, paidMonths: [])
                } label: {
                    Label(isEnglish ? "Add" : "Tambah", systemImage: "plus")
                        .font(.system(size: 12, weight: .heavy)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(LinearGradient(colors: [AppAppearance.accent, AppAppearance.primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                Button { dismiss() } label: {                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("mwlt.transactions.installments.add")
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary).frame(width: 30, height: 30)
                        .background(Color(uiColor: .secondarySystemBackground), in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)                }.buttonStyle(.plain)
                .accessibilityIdentifier("mwlt.transactions.installments.close")
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isEnglish ? "TOTAL MONTHLY INSTALLMENTS" : "TOTAL CICILAN BULANAN")
                            .font(MeowlettTypography.font(size: 10, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.62))
                        Text(rupiah(totalMonthly)).font(MeowlettTypography.font(size: 24, weight: .black)).foregroundStyle(.white)
                        Text("\(items.count) \(isEnglish ? "active items" : "item aktif")")
                            .font(MeowlettTypography.font(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(LinearGradient(colors: [AppAppearance.primary, AppAppearance.accent.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))

                    if items.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "creditcard").font(.system(size: 30, weight: .light)).foregroundStyle(AppAppearance.accent)
                            Text(isEnglish ? "No installments yet" : "Belum ada cicilan")
                                .font(MeowlettTypography.font(size: 14, weight: .bold))
                            Text(isEnglish ? "Add a monthly payment to track its progress." : "Tambahkan pembayaran bulanan untuk melacak progresnya.")
                                .font(MeowlettTypography.font(size: 11, weight: .regular)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 30)
                    } else {
                        ForEach(items) { item in
                            installmentRow(item)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .blur(radius: editorItem == nil ? 0 : 8)
        .animation(.easeInOut(duration: 0.2), value: editorItem != nil)
        .sheet(item: $editorItem) { item in
            NativeInstallmentEditor(item: item) { saved in
                if let index = items.firstIndex(where: { $0.id == saved.id }) { items[index] = saved }
                else { items.append(saved) }
            }
        }
        .onAppear(perform: load)
        .onChange(of: items) { _, value in persist(value) }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private func installmentRow(_ item: NativeInstallment) -> some View {
        let expanded = detailID == item.id
        let paid = item.paidMonths.contains(currentMonth)
        let progress = item.duration > 0 ? min(100, Int(Double(item.paidMonths.count) / Double(item.duration) * 100)) : 0
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { detailID = expanded ? nil : item.id }
            } label: {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 11).fill(AppAppearance.accent.opacity(0.14)).frame(width: 40, height: 40)
                        .overlay(Image(systemName: "creditcard.fill").foregroundStyle(AppAppearance.accent))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name).font(MeowlettTypography.font(size: 13, weight: .bold))
                        Text((isEnglish ? "Due day " : "Jatuh tempo tgl ") + item.dueDay)
                            .font(MeowlettTypography.font(size: 10, weight: .medium)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("-\(rupiah(item.monthly))").font(MeowlettTypography.font(size: 13, weight: .heavy)).foregroundStyle(Color(hex: "#f87171"))
                        Text(paid ? (isEnglish ? "Paid this month" : "Lunas bulan ini") : (isEnglish ? "Not paid yet" : "Belum dibayar"))
                            .font(MeowlettTypography.font(size: 9, weight: .semibold)).foregroundStyle(paid ? Color(hex: "#16a34a") : Color.secondary)
                    }
                    Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold)).foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .padding(13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(isEnglish ? "Progress" : "Progres").font(MeowlettTypography.font(size: 11, weight: .bold)).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(progress)% · \(item.paidMonths.count)/\(item.duration)").font(MeowlettTypography.font(size: 11, weight: .bold))
                    }
                    GeometryReader { proxy in
                        Capsule().fill(Color.primary.opacity(0.06)).overlay(alignment: .leading) {
                            Capsule().fill(AppAppearance.accent).frame(width: proxy.size.width * CGFloat(progress) / 100)
                        }
                    }.frame(height: 7)
                    HStack(spacing: 8) {
                        Button {
                            if !paid, let index = items.firstIndex(where: { $0.id == item.id }) {
                                items[index].paidMonths.append(currentMonth)
                            }
                        } label: {
                            Text(paid ? (isEnglish ? "Already paid" : "Sudah dibayar") : (isEnglish ? "Mark as paid" : "Tandai dibayar"))
                                .font(MeowlettTypography.font(size: 11, weight: .bold)).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).frame(height: 37)
                                .background(paid ? Color.secondary : AppAppearance.primary, in: RoundedRectangle(cornerRadius: 10))
                        }.disabled(paid).buttonStyle(.plain)
                        Button { editorItem = item } label: {
                            Image(systemName: "pencil").foregroundStyle(.primary).frame(width: 38, height: 37)
                                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                        }.buttonStyle(.plain)
                        Button { items.removeAll { $0.id == item.id }; detailID = nil } label: {
                            Image(systemName: "trash").foregroundStyle(Color(hex: "#ef4444")).frame(width: 38, height: 37)
                                .background(Color(hex: "#ef4444").opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.primary.opacity(0.07), lineWidth: 1))
    }

    private func load() {
        guard !loaded else { return }
        if let data = cicilanRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([NativeInstallment].self, from: data) {
            items = decoded
        }
        loaded = true
    }

    private func persist(_ value: [NativeInstallment]) {
        guard loaded, let data = try? JSONEncoder().encode(value), let json = String(data: data, encoding: .utf8) else { return }
        cicilanRaw = json
    }

    private func rupiah(_ value: Int64) -> String {
        let f = NumberFormatter(); f.locale = Locale(identifier: "id_ID"); f.numberStyle = .decimal
        return "Rp" + (f.string(from: NSNumber(value: value)) ?? String(value))
    }
}

private struct NativeInstallmentEditor: View {
    let item: NativeInstallment
    let onSave: (NativeInstallment) -> Void
    @AppStorage("gm_lang") private var language = "id"
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var total: String
    @State private var monthly: String
    @State private var dueDay: String
    @State private var duration: String

    init(item: NativeInstallment, onSave: @escaping (NativeInstallment) -> Void) {
        self.item = item
        self.onSave = onSave
        _name = State(initialValue: item.name)
        _total = State(initialValue: item.total > 0 ? String(item.total) : "")
        _monthly = State(initialValue: item.monthly > 0 ? String(item.monthly) : "")
        _dueDay = State(initialValue: item.dueDay)
        _duration = State(initialValue: String(item.duration))
    }
    private var isEnglish: Bool { language == "en" }

    var body: some View {
        NavigationStack {
            Form {
                Section(isEnglish ? "Installment" : "Cicilan") {
                    TextField(isEnglish ? "Name" : "Nama cicilan", text: $name)
                    TextField(isEnglish ? "Monthly payment" : "Nominal per bulan", text: $monthly).keyboardType(.numberPad)
                    TextField(isEnglish ? "Total amount" : "Total cicilan", text: $total).keyboardType(.numberPad)
                    TextField(isEnglish ? "Due day (1–31)" : "Tanggal jatuh tempo (1–31)", text: $dueDay).keyboardType(.numberPad)
                    TextField(isEnglish ? "Duration (months)" : "Durasi (bulan)", text: $duration).keyboardType(.numberPad)
                }
            }
            .navigationTitle(isEnglish ? "Installment" : "Cicilan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEnglish ? "Cancel" : "Batal") { dismiss() }
                        .accessibilityIdentifier("mwlt.transactions.installments.editor.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEnglish ? "Save" : "Simpan") {
                        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let newItem = NativeInstallment(
                            id: item.id,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            total: Int64(total.filter(\.isNumber)) ?? 0,
                            monthly: Int64(monthly.filter(\.isNumber)) ?? 0,
                            dueDay: String(min(31, max(1, Int(dueDay) ?? 5))),
                            startMonth: item.startMonth,
                            duration: max(1, Int(duration) ?? 12),
                            paidMonths: item.paidMonths
                        )
                        guard newItem.monthly > 0 else { return }
                        onSave(newItem); dismiss()
                    }
                    .accessibilityIdentifier("mwlt.transactions.installments.editor.save")
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Int64(monthly.filter(\.isNumber)) ?? 0) <= 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
