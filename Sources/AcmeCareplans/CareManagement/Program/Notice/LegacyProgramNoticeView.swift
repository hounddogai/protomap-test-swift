import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy program notice.
    final class LegacyProgramNoticeView {
        var code: String
        var labelText: String
        var capacity: String
        var minimum: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, labelText: String, capacity: String, minimum: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.capacity = capacity
            self.minimum = minimum
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyProgramNoticeView(_ item: LegacyProgramNotice) -> LegacyProgramNoticeView {
        return LegacyProgramNoticeView(
            code: item.code,
            labelText: item.label,
            capacity: String(item.capacity),
            minimum: String(format: "%.2f", item.minimum),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyProgramNoticeViews(_ items: [LegacyProgramNotice]) -> [LegacyProgramNoticeView] {
        var views: [LegacyProgramNoticeView] = []
        for item in items {
            views.append(toLegacyProgramNoticeView(item))
        }
        return views
    }

    static func sumLegacyProgramNoticeView(_ view: LegacyProgramNoticeView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedCapacity) + parsedMinimum + Double(parsedDurationMinutes)
    }
}
