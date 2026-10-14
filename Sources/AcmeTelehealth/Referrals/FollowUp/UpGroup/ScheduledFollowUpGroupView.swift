import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a scheduled follow up group.
    final class ScheduledFollowUpGroupView {
        var codeText: String
        var name: String
        var currency: String
        var segment: String
        var endsAtText: String
        var patientRefText: String
        var ratio: String
        var maximum: String
        var discount: String
        var statusLabel: String

        init(codeText: String, name: String, currency: String, segment: String, endsAtText: String, patientRefText: String, ratio: String, maximum: String, discount: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.currency = currency
            self.segment = segment
            self.endsAtText = endsAtText
            self.patientRefText = patientRefText
            self.ratio = ratio
            self.maximum = maximum
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledFollowUpGroupView(_ item: ScheduledFollowUpGroup) -> ScheduledFollowUpGroupView {
        return ScheduledFollowUpGroupView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            currency: item.currency,
            segment: item.segment,
            endsAtText: String(item.endsAt),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 80),
            ratio: String(format: "%.2f", item.ratio),
            maximum: String(format: "%.2f", item.maximum),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledFollowUpGroupViews(_ items: [ScheduledFollowUpGroup]) -> [ScheduledFollowUpGroupView] {
        var views: [ScheduledFollowUpGroupView] = []
        for item in items {
            views.append(toScheduledFollowUpGroupView(item))
        }
        return views
    }

    static func sumScheduledFollowUpGroupView(_ view: ScheduledFollowUpGroupView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedEndsAt) + parsedRatio + parsedMaximum
    }
}
