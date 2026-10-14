import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a capped rounding schedule.
    final class CappedRoundingScheduleView {
        var codeText: String
        var label: String
        var weightText: String
        var durationMinutesText: String
        var region: String
        var statusLabel: String

        init(codeText: String, label: String, weightText: String, durationMinutesText: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.weightText = weightText
            self.durationMinutesText = durationMinutesText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toCappedRoundingScheduleView(_ item: CappedRoundingSchedule) -> CappedRoundingScheduleView {
        return CappedRoundingScheduleView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            weightText: String(format: "%.2f", item.weight),
            durationMinutesText: String(item.durationMinutes),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedRoundingScheduleViews(_ items: [CappedRoundingSchedule]) -> [CappedRoundingScheduleView] {
        var views: [CappedRoundingScheduleView] = []
        for item in items {
            views.append(toCappedRoundingScheduleView(item))
        }
        return views
    }

    static func sumCappedRoundingScheduleView(_ view: CappedRoundingScheduleView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedWeight + Double(parsedDurationMinutes)
    }
}
