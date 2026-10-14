import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal reference range schedule.
    final class SeasonalReferenceRangeScheduleView {
        var codeText: String
        var title: String
        var retries: String
        var thresholdText: String
        var active: String
        var visible: String
        var rate: String
        var statusLabel: String

        init(codeText: String, title: String, retries: String, thresholdText: String, active: String, visible: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.retries = retries
            self.thresholdText = thresholdText
            self.active = active
            self.visible = visible
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalReferenceRangeScheduleView(_ item: SeasonalReferenceRangeSchedule) -> SeasonalReferenceRangeScheduleView {
        return SeasonalReferenceRangeScheduleView(
            codeText: item.code,
            title: item.title,
            retries: String(item.retries),
            thresholdText: String(format: "%.2f", item.threshold),
            active: "\(item.active)",
            visible: "\(item.visible)",
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalReferenceRangeScheduleViews(_ items: [SeasonalReferenceRangeSchedule]) -> [SeasonalReferenceRangeScheduleView] {
        var views: [SeasonalReferenceRangeScheduleView] = []
        for item in items {
            views.append(toSeasonalReferenceRangeScheduleView(item))
        }
        return views
    }

    static func sumSeasonalReferenceRangeScheduleView(_ view: SeasonalReferenceRangeScheduleView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedRetries) + parsedThreshold + parsedRate
    }
}
