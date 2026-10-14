import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness budget.
    final class WitnessBudgetView {
        var code: String
        var name: String
        var allergy: String
        var createdAt: String
        var externalRef: String
        var notes: String
        var ratioText: String
        var refills: String
        var regionText: String
        var statusLabel: String

        init(code: String, name: String, allergy: String, createdAt: String, externalRef: String, notes: String, ratioText: String, refills: String, regionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.createdAt = createdAt
            self.externalRef = externalRef
            self.notes = notes
            self.ratioText = ratioText
            self.refills = refills
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessBudgetView(_ item: WitnessBudget) -> WitnessBudgetView {
        return WitnessBudgetView(
            code: item.code,
            name: item.name,
            allergy: item.allergy,
            createdAt: String(item.createdAt),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            notes: item.notes,
            ratioText: String(format: "%.2f", item.ratio),
            refills: String(item.refills),
            regionText: Kit.Text.truncate(item.region, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessBudgetViews(_ items: [WitnessBudget]) -> [WitnessBudgetView] {
        var views: [WitnessBudgetView] = []
        for item in items {
            views.append(toWitnessBudgetView(item))
        }
        return views
    }

    static func sumWitnessBudgetView(_ view: WitnessBudgetView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedCreatedAt) + parsedRatio + Double(parsedRefills)
    }
}
