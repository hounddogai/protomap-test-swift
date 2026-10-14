import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan schedule.
    final class DischargePlanScheduleView {
        var code: String
        var titleText: String
        var weightText: String
        var attempts: String
        var externalRef: String
        var category: String
        var locale: String
        var ratioText: String
        var capacity: String
        var statusLabel: String

        init(code: String, titleText: String, weightText: String, attempts: String, externalRef: String, category: String, locale: String, ratioText: String, capacity: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.weightText = weightText
            self.attempts = attempts
            self.externalRef = externalRef
            self.category = category
            self.locale = locale
            self.ratioText = ratioText
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanScheduleView(_ item: DischargePlanSchedule) -> DischargePlanScheduleView {
        return DischargePlanScheduleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            weightText: String(format: "%.2f", item.weight),
            attempts: String(item.attempts),
            externalRef: item.externalRef,
            category: item.category,
            locale: item.locale,
            ratioText: String(format: "%.2f", item.ratio),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanScheduleViews(_ items: [DischargePlanSchedule]) -> [DischargePlanScheduleView] {
        var views: [DischargePlanScheduleView] = []
        for item in items {
            views.append(toDischargePlanScheduleView(item))
        }
        return views
    }

    static func sumDischargePlanScheduleView(_ view: DischargePlanScheduleView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedWeight + Double(parsedAttempts) + parsedRatio
    }
}
