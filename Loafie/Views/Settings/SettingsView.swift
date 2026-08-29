import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(NotificationService.self) private var notificationService
    @Environment(SessionStore.self) private var sessionStore

    @State private var versionTapCount = 0
    @State private var showsDebugSettings = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Notifications", isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: setNotificationsEnabled
                    ))
                    Picker("Notification sound", selection: $settings.notificationSound) {
                        ForEach(NotificationSound.allCases) { sound in
                            Text(sound.title).tag(sound)
                        }
                    }
                    .disabled(!settings.notificationsEnabled)

                    Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)

                    if #available(iOS 26.0, *) {
                        Toggle("Use system alarms", isOn: Binding(
                            get: { settings.alarmKitEnabled },
                            set: setAlarmKitEnabled
                        ))
                        .disabled(!notificationService.alarmKitAvailable)
                    }
                }
                .listRowBackground(Color.doughBeige)

                if #available(iOS 26.0, *), settings.alarmKitEnabled {
                    Section {
                        Toggle("Quiet hours", isOn: Binding(
                            get: { settings.sleepModeEnabled },
                            set: setSleepModeEnabled
                        ))
                        DatePicker(
                            "Start",
                            selection: sleepTimeBinding(isStart: true),
                            displayedComponents: .hourAndMinute
                        )
                        .disabled(!settings.sleepModeEnabled)
                        DatePicker(
                            "End",
                            selection: sleepTimeBinding(isStart: false),
                            displayedComponents: .hourAndMinute
                        )
                        .disabled(!settings.sleepModeEnabled)
                    } header: {
                        Text("Quiet hours")
                    } footer: {
                        Text("During quiet hours, fold and step reminders are silenced. Important step-end warnings are still delivered.")
                    }
                    .listRowBackground(Color.doughBeige)
                }

                if showsDebugSettings {
                    Section("Timer") {
                        Toggle("Ask before adjusting the plan", isOn: $settings.askBeforePlanAdjustment)
                    }
                    .listRowBackground(Color.doughBeige)
                }

                Section("About") {
                    Button(action: registerVersionTap) {
                        LabeledContent("Version", value: appVersion)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Tap five times to show advanced settings.")
                }
                .listRowBackground(Color.doughBeige)

                if #available(iOS 26.0, *),
                   showsDebugSettings,
                   notificationService.alarmKitAvailable {
                    alarmKitDiagnostics
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Color.flourCream)
            .tint(.sourdoughBrown)
            .listStyle(.insetGrouped)
            .task {
                await notificationService.refreshDiagnostics()
            }
            .onChange(of: settings.notificationSound) { _, sound in
                notificationService.playPreview(for: sound)
                rescheduleCurrentSession()
            }
        }
    }

    @ViewBuilder
    private var alarmKitDiagnostics: some View {
        Section("System alarm diagnostics") {
            LabeledContent("Availability", value: "Available")
            LabeledContent("Permission", value: notificationService.alarmKitAuthorized ? "Allowed" : "Not Allowed")
            LabeledContent("Scheduled system alarms", value: "\(notificationService.scheduledAlarmCount)")
            if notificationService.scheduledAlarms.isEmpty {
                Text("No system alarms scheduled.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(notificationService.scheduledAlarms) { alarm in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(alarm.title)
                            .font(.subheadline.weight(.medium))
                        Text(alarm.scheduledAt, format: .dateTime.weekday(.abbreviated).hour().minute().second())
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(alarm.identifier)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            if let status = notificationService.lastSchedulingStatus {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let error = notificationService.lastSchedulingError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Button("Refresh diagnostics") {
                Task { await notificationService.refreshDiagnostics() }
            }
        }
        .listRowBackground(Color.doughBeige)
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"
        return "\(version) (\(build))"
    }

    private func setNotificationsEnabled(_ enabled: Bool) {
        settings.notificationsEnabled = enabled
        if enabled {
            Task { @MainActor in
                _ = await notificationService.requestAuthorization()
                rescheduleCurrentSession()
            }
            return
        }
        rescheduleCurrentSession()
    }

    private func setAlarmKitEnabled(_ enabled: Bool) {
        guard enabled else {
            settings.alarmKitEnabled = false
            rescheduleCurrentSession()
            return
        }

        Task { @MainActor in
            let authorized = await notificationService.requestAlarmKitAuthorization()
            settings.alarmKitEnabled = authorized
            rescheduleCurrentSession()
        }
    }

    private func setSleepModeEnabled(_ enabled: Bool) {
        settings.sleepModeEnabled = enabled
        rescheduleCurrentSession()
    }

    private func sleepTimeBinding(isStart: Bool) -> Binding<Date> {
        Binding {
            let minute = isStart ? settings.sleepModeStartMinute : settings.sleepModeEndMinute
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = minute / 60
            components.minute = minute % 60
            return Calendar.current.date(from: components) ?? Date()
        } set: { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            if isStart {
                settings.sleepModeStartMinute = minute
            } else {
                settings.sleepModeEndMinute = minute
            }
            rescheduleCurrentSession()
        }
    }

    private func registerVersionTap() {
        versionTapCount += 1
        if versionTapCount >= 5 {
            showsDebugSettings = true
        }
    }

    private func rescheduleCurrentSession() {
        if let session = sessionStore.currentSession() {
            notificationService.reschedule(for: session)
        }
    }
}
