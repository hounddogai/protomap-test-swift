import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach override.
    final class OutreachOverrideView {
        var code: String
        var titleText: String
        var startsAtText: String
        var unit: String
        var discountText: String
        var acuity: String
        var visitMinutesText: String
        var approved: String
        var label: String
        var minimum: String
        var thresholdText: String
        var statusLabel: String

        init(code: String, titleText: String, startsAtText: String, unit: String, discountText: String, acuity: String, visitMinutesText: String, approved: String, label: String, minimum: String, thresholdText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.startsAtText = startsAtText
            self.unit = unit
            self.discountText = discountText
            self.acuity = acuity
            self.visitMinutesText = visitMinutesText
            self.approved = approved
            self.label = label
            self.minimum = minimum
            self.thresholdText = thresholdText
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachOverrideView(_ item: OutreachOverride) -> OutreachOverrideView {
        return OutreachOverrideView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            startsAtText: String(item.startsAt),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            discountText: String(format: "%.2f", item.discount),
            acuity: String(item.acuity),
            visitMinutesText: String(item.visitMinutes),
            approved: "\(item.approved)",
            label: item.label,
            minimum: String(format: "%.2f", item.minimum),
            thresholdText: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachOverrideViews(_ items: [OutreachOverride]) -> [OutreachOverrideView] {
        var views: [OutreachOverrideView] = []
        for item in items {
            views.append(toOutreachOverrideView(item))
        }
        return views
    }

    static func sumOutreachOverrideView(_ view: OutreachOverrideView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedStartsAt) + parsedDiscount + Double(parsedAcuity)
    }
}
