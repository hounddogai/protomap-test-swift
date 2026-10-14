import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a weighted discharge plan estimate.
    final class WeightedDischargePlanEstimateView {
        var code: String
        var label: String
        var clinicianID: String
        var minimum: String
        var contactEmailText: String
        var updatedAt: String
        var country: String
        var budgetText: String
        var segment: String
        var locale: String
        var statusLabel: String

        init(code: String, label: String, clinicianID: String, minimum: String, contactEmailText: String, updatedAt: String, country: String, budgetText: String, segment: String, locale: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.minimum = minimum
            self.contactEmailText = contactEmailText
            self.updatedAt = updatedAt
            self.country = country
            self.budgetText = budgetText
            self.segment = segment
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedDischargePlanEstimateView(_ item: WeightedDischargePlanEstimate) -> WeightedDischargePlanEstimateView {
        return WeightedDischargePlanEstimateView(
            code: item.code,
            label: item.label,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            minimum: String(format: "%.2f", item.minimum),
            contactEmailText: item.contactEmail,
            updatedAt: String(item.updatedAt),
            country: Kit.Text.truncate(item.country, limit: 40),
            budgetText: String(format: "%.2f", item.budget),
            segment: item.segment,
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedDischargePlanEstimateViews(_ items: [WeightedDischargePlanEstimate]) -> [WeightedDischargePlanEstimateView] {
        var views: [WeightedDischargePlanEstimateView] = []
        for item in items {
            views.append(toWeightedDischargePlanEstimateView(item))
        }
        return views
    }

    static func sumWeightedDischargePlanEstimateView(_ view: WeightedDischargePlanEstimateView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedMinimum + Double(parsedUpdatedAt) + parsedBudget
    }
}
