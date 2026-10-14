import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form plan.
    final class ConsentFormPlanView {
        var code: String
        var nameText: String
        var currency: String
        var updatedAt: String
        var floorValue: String
        var procedureCode: String
        var margin: String
        var budget: String
        var weight: String
        var sequence: String
        var statusLabel: String

        init(code: String, nameText: String, currency: String, updatedAt: String, floorValue: String, procedureCode: String, margin: String, budget: String, weight: String, sequence: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.currency = currency
            self.updatedAt = updatedAt
            self.floorValue = floorValue
            self.procedureCode = procedureCode
            self.margin = margin
            self.budget = budget
            self.weight = weight
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormPlanView(_ item: ConsentFormPlan) -> ConsentFormPlanView {
        return ConsentFormPlanView(
            code: item.code,
            nameText: item.name,
            currency: Kit.Text.truncate(item.currency, limit: 120),
            updatedAt: String(item.updatedAt),
            floorValue: String(format: "%.2f", item.floorValue),
            procedureCode: item.procedureCode,
            margin: String(format: "%.2f", item.margin),
            budget: String(format: "%.2f", item.budget),
            weight: String(format: "%.2f", item.weight),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormPlanViews(_ items: [ConsentFormPlan]) -> [ConsentFormPlanView] {
        var views: [ConsentFormPlanView] = []
        for item in items {
            views.append(toConsentFormPlanView(item))
        }
        return views
    }

    static func sumConsentFormPlanView(_ view: ConsentFormPlanView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedUpdatedAt) + parsedFloorValue + parsedMargin
    }
}
