import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling care gap schedule.
    final class RollingCareGapScheduleView {
        var codeText: String
        var title: String
        var archived: String
        var diagnosisCode: String
        var rateText: String
        var capacity: String
        var currencyText: String
        var summaryText: String
        var statusLabel: String

        init(codeText: String, title: String, archived: String, diagnosisCode: String, rateText: String, capacity: String, currencyText: String, summaryText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.archived = archived
            self.diagnosisCode = diagnosisCode
            self.rateText = rateText
            self.capacity = capacity
            self.currencyText = currencyText
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCareGapScheduleView(_ item: RollingCareGapSchedule) -> RollingCareGapScheduleView {
        return RollingCareGapScheduleView(
            codeText: item.code,
            title: item.title,
            archived: "\(item.archived)",
            diagnosisCode: item.diagnosisCode,
            rateText: String(format: "%.2f", item.rate),
            capacity: String(item.capacity),
            currencyText: Kit.Text.truncate(item.currency, limit: 40),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCareGapScheduleViews(_ items: [RollingCareGapSchedule]) -> [RollingCareGapScheduleView] {
        var views: [RollingCareGapScheduleView] = []
        for item in items {
            views.append(toRollingCareGapScheduleView(item))
        }
        return views
    }

    static func sumRollingCareGapScheduleView(_ view: RollingCareGapScheduleView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedRate + Double(parsedCapacity)
    }
}
