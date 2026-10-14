import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility summary.
    final class EligibilitySummaryView {
        var code: String
        var title: String
        var notes: String
        var updatedAt: String
        var ceilingText: String
        var marginText: String
        var priorityText: String
        var checksumText: String
        var timezoneText: String
        var statusLabel: String

        init(code: String, title: String, notes: String, updatedAt: String, ceilingText: String, marginText: String, priorityText: String, checksumText: String, timezoneText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notes = notes
            self.updatedAt = updatedAt
            self.ceilingText = ceilingText
            self.marginText = marginText
            self.priorityText = priorityText
            self.checksumText = checksumText
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilitySummaryView(_ item: EligibilitySummary) -> EligibilitySummaryView {
        return EligibilitySummaryView(
            code: item.code,
            title: item.title,
            notes: item.notes,
            updatedAt: String(item.updatedAt),
            ceilingText: String(format: "%.2f", item.ceiling),
            marginText: String(format: "%.2f", item.margin),
            priorityText: String(item.priority),
            checksumText: item.checksum,
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilitySummaryViews(_ items: [EligibilitySummary]) -> [EligibilitySummaryView] {
        var views: [EligibilitySummaryView] = []
        for item in items {
            views.append(toEligibilitySummaryView(item))
        }
        return views
    }

    static func sumEligibilitySummaryView(_ view: EligibilitySummaryView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedUpdatedAt) + parsedCeiling + parsedMargin
    }
}
