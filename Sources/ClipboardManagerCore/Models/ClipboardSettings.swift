import Foundation

public enum RetentionPeriod: String, CaseIterable, Identifiable {
    case session, fiveMinutes, fifteenMinutes, thirtyMinutes
    case oneHour, fourHours, twelveHours, oneDay

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .session: return "Until App Closes"
        case .fiveMinutes: return "5 Minutes"
        case .fifteenMinutes: return "15 Minutes"
        case .thirtyMinutes: return "30 Minutes"
        case .oneHour: return "1 Hour"
        case .fourHours: return "4 Hours"
        case .twelveHours: return "12 Hours"
        case .oneDay: return "1 Day"
        }
    }

    public var duration: TimeInterval? {
        switch self {
        case .session: return nil
        case .fiveMinutes: return 300
        case .fifteenMinutes: return 900
        case .thirtyMinutes: return 1800
        case .oneHour: return 3600
        case .fourHours: return 14400
        case .twelveHours: return 43200
        case .oneDay: return 86400
        }
    }
}

public struct ClipboardSettings {
    public var retentionPeriod: RetentionPeriod
    public var maxItems: Int
    public var maxMemoryMB: Int

    public init(
        retentionPeriod: RetentionPeriod = .session,
        maxItems: Int = 500,
        maxMemoryMB: Int = 512
    ) {
        self.retentionPeriod = retentionPeriod
        self.maxItems = maxItems
        self.maxMemoryMB = maxMemoryMB
    }

    public var maxMemoryBytes: Int { maxMemoryMB * 1024 * 1024 }
}
