import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility profile.
    final class EligibilityProfileView {
        var code: String
        var label: String
        var amount: String
        var patientRef: String
        var countryText: String
        var minimum: String
        var locale: String
        var createdAt: String
        var endsAt: String
        var statusLabel: String

        init(code: String, label: String, amount: String, patientRef: String, countryText: String, minimum: String, locale: String, createdAt: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.amount = amount
            self.patientRef = patientRef
            self.countryText = countryText
            self.minimum = minimum
            self.locale = locale
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityProfileView(_ item: EligibilityProfile) -> EligibilityProfileView {
        return EligibilityProfileView(
            code: item.code,
            label: item.label,
            amount: String(format: "%.2f", item.amount),
            patientRef: item.patientRef,
            countryText: item.country,
            minimum: String(format: "%.2f", item.minimum),
            locale: item.locale,
            createdAt: String(item.createdAt),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityProfileViews(_ items: [EligibilityProfile]) -> [EligibilityProfileView] {
        var views: [EligibilityProfileView] = []
        for item in items {
            views.append(toEligibilityProfileView(item))
        }
        return views
    }

    static func sumEligibilityProfileView(_ view: EligibilityProfileView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedAmount + parsedMinimum + Double(parsedCreatedAt)
    }
}
