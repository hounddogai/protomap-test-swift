import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled outreach request.
    final class ScheduledOutreachRequestView {
        var codeText: String
        var name: String
        var title: String
        var timezoneText: String
        var bed: String
        var locale: String
        var reviewer: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, name: String, title: String, timezoneText: String, bed: String, locale: String, reviewer: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.title = title
            self.timezoneText = timezoneText
            self.bed = bed
            self.locale = locale
            self.reviewer = reviewer
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledOutreachRequestView(_ item: ScheduledOutreachRequest) -> ScheduledOutreachRequestView {
        return ScheduledOutreachRequestView(
            codeText: item.code,
            name: item.name,
            title: item.title,
            timezoneText: item.timezone,
            bed: item.bed,
            locale: item.locale,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledOutreachRequestViews(_ items: [ScheduledOutreachRequest]) -> [ScheduledOutreachRequestView] {
        var views: [ScheduledOutreachRequestView] = []
        for item in items {
            views.append(toScheduledOutreachRequestView(item))
        }
        return views
    }

    static func sumScheduledOutreachRequestView(_ view: ScheduledOutreachRequestView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
