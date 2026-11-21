import SwiftUI
import UserNotifications

struct SettingsReminderSheet: View {
    @AppStorage("gm_lang") private var language = "id"
    @AppStorage("gm_notif") private var notificationEnabled = "0"
    @AppStorage("gm_reminder_hour") private var reminderHour = "21"
    @AppStorage("gm_reminder_days") private var reminderDaysRaw = "[1,2,3,4,5]"
    @AppStorage("gm_reminder_smart") private var reminderSmart = "1"

    @Environment(\.dismiss) private var dismiss
    @State private var reminderDays = [1,2,3,4,5]
    @State private var loaded = false
    @State private var permissionMessage = ""

    private var isEnglish: Bool { language == "en" }
    private var hour: Int { Int(reminderHour) ?? 21 }
    private var dayLabels: [String] { isEnglish ? ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"] : ["Min","Sen","Sel","Rab","Kam","Jum","Sab"] }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 36, height: 4).padding(.top, 12)
            HStack {
                Label(isEnglish ? "Payment reminders" : "Pengingat tagihan", systemImage: "bell")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.primary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary).frame(width: 30, height: 30)
                        .background(Color(uiColor: .secondarySystemBackground), in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            Divider().opacity(0.5)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(LinearGradient(colors: [AppAppearance.accent, AppAppearance.primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(isEnglish ? "Stay on track" : "Jangan lupa mencatat")
                                .font(.system(size: 14, weight: .heavy))
                            Text(isEnglish ? "Choose when Meowlett reminds you." : "Atur kapan Meowlett mengingatkanmu.")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .background(AppAppearance.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppAppearance.accent.opacity(0.18), lineWidth: 1))
                    .padding(16)

                    settingsToggle(
                        symbol: notificationEnabled == "1" ? "bell.fill" : "bell.slash",
                        title: isEnglish ? "Notifications" : "Notifikasi",
                        subtitle: notificationEnabled == "1" ? (isEnglish ? "Active" : "Aktif") : (isEnglish ? "Off" : "Nonaktif"),
                        isOn: Binding(get: { notificationEnabled == "1" }, set: { value in Task { await setNotifications(value) } })
                    )
                    Divider().padding(.leading, 20)

                    HStack(spacing: 12) {
                        Image(systemName: "alarm").font(.system(size: 18)).foregroundStyle(.secondary)
                            .frame(width: 38, height: 38).background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isEnglish ? "Reminder time" : "Waktu pengingat").font(.system(size: 14, weight: .bold))
                            Text(isEnglish ? "Notifications are sent at this time" : "Notifikasi dikirim pada jam ini").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $reminderHour) {
                            ForEach([6,7,8,9,10,12,15,18,19,20,21,22], id: \.self) { value in
                                Text(String(format: "%02d:00", value)).tag(String(value))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppAppearance.accent)
                        .font(.system(size: 15, weight: .black))
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    Divider().padding(.leading, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(isEnglish ? "Reminder days" : "Hari pengingat")
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { day in
                                let selected = reminderDays.contains(day)
                                Button {
                                    if selected { reminderDays.removeAll { $0 == day } }
                                    else { reminderDays.append(day); reminderDays.sort() }
                                } label: {
                                    Text(dayLabels[day])
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(selected ? AppAppearance.accent : Color.secondary)
                                        .frame(maxWidth: .infinity).frame(height: 38)
                                        .background(selected ? AppAppearance.accent.opacity(0.13) : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? AppAppearance.accent.opacity(0.45) : Color.primary.opacity(0.07), lineWidth: 1.5))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    Divider().padding(.leading, 20)

                    settingsToggle(
                        symbol: "sparkles",
                        title: isEnglish ? "Smart reminder" : "Pengingat pintar",
                        subtitle: isEnglish ? "Adapt reminder content to your activity" : "Sesuaikan isi pengingat dengan aktivitasmu",
                        isOn: Binding(get: { reminderSmart != "0" }, set: { reminderSmart = $0 ? "1" : "0" })
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(isEnglish ? "NOTIFICATION PREVIEW" : "PREVIEW NOTIFIKASI")
                            .font(.system(size: 10, weight: .heavy)).tracking(0.5).foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 8) {
                                Text("🐱").font(.system(size: 15)).frame(width: 28, height: 28).background(AppAppearance.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                                Text("Meowlett").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%02d:00", hour)).font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            Text(isEnglish ? "Time to record your spending!" : "Waktunya mencatat pengeluaran!")
                                .font(.system(size: 13, weight: .heavy))
                            Text(isEnglish ? "Keep your finances organized with a quick daily update." : "Yuk catat aktivitas hari ini agar keuanganmu tetap rapi.")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 15))
                    }
                    .padding(16)
                }
                .padding(.bottom, 18)
            }
            Button(isEnglish ? "Save settings" : "Simpan Pengaturan") {
                saveDays()
                if notificationEnabled == "1" { scheduleNotifications() }
                dismiss()
            }
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(LinearGradient(colors: [AppAppearance.accent, AppAppearance.primary], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
        }
        .background(Color(uiColor: .systemBackground))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .onAppear {
            if let data = reminderDaysRaw.data(using: .utf8),
               let decoded = try? JSONDecoder().decode([Int].self, from: data) {
                reminderDays = decoded
            }
            loaded = true
        }
        .onChange(of: reminderDays) { _, _ in saveDays() }
        .onChange(of: reminderHour) { _, _ in if notificationEnabled == "1" { scheduleNotifications() } }
        .onChange(of: reminderSmart) { _, _ in if notificationEnabled == "1" { scheduleNotifications() } }
    }

    private func settingsToggle(symbol: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 17, weight: .semibold)).foregroundStyle(AppAppearance.accent)
                .frame(width: 38, height: 38).background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .bold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(AppAppearance.primary)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    private func setNotifications(_ value: Bool) async {
        if value {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    notificationEnabled = granted ? "1" : "0"
                    if granted { scheduleNotifications() }
                    else { permissionMessage = isEnglish ? "Notification permission was denied." : "Izin notifikasi ditolak." }
                }
            } catch {
                await MainActor.run {
                    notificationEnabled = "0"
                    permissionMessage = error.localizedDescription
                }
            }
        } else {
            notificationEnabled = "0"
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: (0..<7).map { "meowlett-reminder-\($0)" })
        }
    }

    private func saveDays() {
        guard loaded, let data = try? JSONEncoder().encode(reminderDays), let json = String(data: data, encoding: .utf8) else { return }
        reminderDaysRaw = json
    }

    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<7).map { "meowlett-reminder-\($0)" })
        let content = UNMutableNotificationContent()
        content.title = "Meowlett"
        content.body = isEnglish ? "Time to record your spending!" : "Waktunya mencatat pengeluaran hari ini!"
        content.sound = .default
        for day in reminderDays {
            var components = DateComponents()
            components.weekday = day + 1
            components.hour = hour
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "meowlett-reminder-\(day)", content: content, trigger: trigger)
            center.add(request)
        }
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
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary).frame(width: 30, height: 30)
                        .background(Color(uiColor: .secondarySystemBackground), in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isEnglish ? "TOTAL MONTHLY INSTALLMENTS" : "TOTAL CICILAN BULANAN")
                            .font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.62))
                        Text(rupiah(totalMonthly)).font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(.white)
                        Text("\(items.count) \(isEnglish ? "active items" : "item aktif")")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(LinearGradient(colors: [AppAppearance.primary, AppAppearance.accent.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))

                    if items.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "creditcard").font(.system(size: 30, weight: .light)).foregroundStyle(AppAppearance.accent)
                            Text(isEnglish ? "No installments yet" : "Belum ada cicilan")
                                .font(.system(size: 14, weight: .bold))
                            Text(isEnglish ? "Add a monthly payment to track its progress." : "Tambahkan pembayaran bulanan untuk melacak progresnya.")
                                .font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
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
                        Text(item.name).font(.system(size: 13, weight: .bold))
                        Text((isEnglish ? "Due day " : "Jatuh tempo tgl ") + item.dueDay)
                            .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("-\(rupiah(item.monthly))").font(.system(size: 13, weight: .heavy)).foregroundStyle(Color(hex: "#f87171"))
                        Text(paid ? (isEnglish ? "Paid this month" : "Lunas bulan ini") : (isEnglish ? "Not paid yet" : "Belum dibayar"))
                            .font(.system(size: 9, weight: .semibold)).foregroundStyle(paid ? Color(hex: "#16a34a") : Color.secondary)
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
                        Text(isEnglish ? "Progress" : "Progres").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(progress)% · \(item.paidMonths.count)/\(item.duration)").font(.system(size: 11, weight: .bold))
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
                                .font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
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
                ToolbarItem(placement: .cancellationAction) { Button(isEnglish ? "Cancel" : "Batal") { dismiss() } }
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Int64(monthly.filter(\.isNumber)) ?? 0) <= 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
