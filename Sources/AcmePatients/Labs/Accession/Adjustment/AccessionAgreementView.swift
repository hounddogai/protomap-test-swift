import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession agreement.
    final class AccessionAgreementView {
        var code: String
        var titleText: String
        var costText: String
        var visitMinutesText: String
        var graceDays: String
        var notes: String
        var maximum: String
        var active: String
        var durationMinutesText: String
        var windowDays: String
        var statusLabel: String

        init(code: String, titleText: String, costText: String, visitMinutesText: String, graceDays: String, notes: String, maximum: String, active: String, durationMinutesText: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.costText = costText
            self.visitMinutesText = visitMinutesText
            self.graceDays = graceDays
            self.notes = notes
            self.maximum = maximum
            self.active = active
            self.durationMinutesText = durationMinutesText
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionAgreementView(_ item: AccessionAgreement) -> AccessionAgreementView {
        return AccessionAgreementView(
            code: item.code,
            titleText: item.title,
            costText: String(format: "%.2f", item.cost),
            visitMinutesText: String(item.visitMinutes),
            graceDays: String(item.graceDays),
            notes: Kit.Text.truncate(item.notes, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            active: "\(item.active)",
            durationMinutesText: String(item.durationMinutes),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionAgreementViews(_ items: [AccessionAgreement]) -> [AccessionAgreementView] {
        var views: [AccessionAgreementView] = []
        for item in items {
            views.append(toAccessionAgreementView(item))
        }
        return views
    }

    static func sumAccessionAgreementView(_ view: AccessionAgreementView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedCost + Double(parsedVisitMinutes) + Double(parsedGraceDays)
    }
}
