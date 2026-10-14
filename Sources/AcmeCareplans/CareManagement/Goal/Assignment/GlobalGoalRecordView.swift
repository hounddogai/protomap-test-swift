import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global goal record.
    final class GlobalGoalRecordView {
        var code: String
        var title: String
        var ward: String
        var region: String
        var visible: String
        var weightText: String
        var timezoneText: String
        var attempts: String
        var statusLabel: String

        init(code: String, title: String, ward: String, region: String, visible: String, weightText: String, timezoneText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ward = ward
            self.region = region
            self.visible = visible
            self.weightText = weightText
            self.timezoneText = timezoneText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalGoalRecordView(_ item: GlobalGoalRecord) -> GlobalGoalRecordView {
        return GlobalGoalRecordView(
            code: item.code,
            title: item.title,
            ward: item.ward,
            region: item.region,
            visible: "\(item.visible)",
            weightText: String(format: "%.2f", item.weight),
            timezoneText: item.timezone,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalGoalRecordViews(_ items: [GlobalGoalRecord]) -> [GlobalGoalRecordView] {
        var views: [GlobalGoalRecordView] = []
        for item in items {
            views.append(toGlobalGoalRecordView(item))
        }
        return views
    }

    static func sumGlobalGoalRecordView(_ view: GlobalGoalRecordView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedWeight + Double(parsedAttempts)
    }
}
