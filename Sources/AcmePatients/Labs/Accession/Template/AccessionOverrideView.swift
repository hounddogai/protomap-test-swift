import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession override.
    final class AccessionOverrideView {
        var code: String
        var titleText: String
        var amount: String
        var timezoneText: String
        var refills: String
        var copay: String
        var acuity: String
        var minimum: String
        var statusLabel: String

        init(code: String, titleText: String, amount: String, timezoneText: String, refills: String, copay: String, acuity: String, minimum: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.amount = amount
            self.timezoneText = timezoneText
            self.refills = refills
            self.copay = copay
            self.acuity = acuity
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionOverrideView(_ item: AccessionOverride) -> AccessionOverrideView {
        return AccessionOverrideView(
            code: item.code,
            titleText: item.title,
            amount: String(format: "%.2f", item.amount),
            timezoneText: item.timezone,
            refills: String(item.refills),
            copay: String(format: "%.2f", item.copay),
            acuity: String(item.acuity),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionOverrideViews(_ items: [AccessionOverride]) -> [AccessionOverrideView] {
        var views: [AccessionOverrideView] = []
        for item in items {
            views.append(toAccessionOverrideView(item))
        }
        return views
    }

    static func sumAccessionOverrideView(_ view: AccessionOverrideView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedAmount + Double(parsedRefills) + parsedCopay
    }
}
