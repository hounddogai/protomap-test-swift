import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a seasonal handoff policy.
    final class SeasonalHandoffPolicyView {
        var code: String
        var name: String
        var ward: String
        var visible: String
        var amount: String
        var facility: String
        var encounterID: String
        var discount: String
        var clinicianID: String
        var specialty: String
        var budget: String
        var statusLabel: String

        init(code: String, name: String, ward: String, visible: String, amount: String, facility: String, encounterID: String, discount: String, clinicianID: String, specialty: String, budget: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ward = ward
            self.visible = visible
            self.amount = amount
            self.facility = facility
            self.encounterID = encounterID
            self.discount = discount
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalHandoffPolicyView(_ item: SeasonalHandoffPolicy) -> SeasonalHandoffPolicyView {
        return SeasonalHandoffPolicyView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            ward: item.ward,
            visible: "\(item.visible)",
            amount: String(format: "%.2f", item.amount),
            facility: item.facility,
            encounterID: item.encounterID,
            discount: String(format: "%.2f", item.discount),
            clinicianID: item.clinicianID,
            specialty: item.specialty,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalHandoffPolicyViews(_ items: [SeasonalHandoffPolicy]) -> [SeasonalHandoffPolicyView] {
        var views: [SeasonalHandoffPolicyView] = []
        for item in items {
            views.append(toSeasonalHandoffPolicyView(item))
        }
        return views
    }

    static func sumSeasonalHandoffPolicyView(_ view: SeasonalHandoffPolicyView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedAmount + parsedDiscount + parsedBudget
    }
}
