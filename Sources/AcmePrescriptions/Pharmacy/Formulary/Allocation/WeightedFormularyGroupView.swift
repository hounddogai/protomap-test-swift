import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted formulary group.
    final class WeightedFormularyGroupView {
        var code: String
        var label: String
        var currency: String
        var score: String
        var summaryText: String
        var ceiling: String
        var specialty: String
        var approved: String
        var nameText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, label: String, currency: String, score: String, summaryText: String, ceiling: String, specialty: String, approved: String, nameText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.currency = currency
            self.score = score
            self.summaryText = summaryText
            self.ceiling = ceiling
            self.specialty = specialty
            self.approved = approved
            self.nameText = nameText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedFormularyGroupView(_ item: WeightedFormularyGroup) -> WeightedFormularyGroupView {
        return WeightedFormularyGroupView(
            code: item.code,
            label: item.label,
            currency: item.currency,
            score: String(format: "%.2f", item.score),
            summaryText: Kit.Text.truncate(item.summary, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            specialty: item.specialty,
            approved: "\(item.approved)",
            nameText: item.name,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedFormularyGroupViews(_ items: [WeightedFormularyGroup]) -> [WeightedFormularyGroupView] {
        var views: [WeightedFormularyGroupView] = []
        for item in items {
            views.append(toWeightedFormularyGroupView(item))
        }
        return views
    }

    static func sumWeightedFormularyGroupView(_ view: WeightedFormularyGroupView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedScore + parsedCeiling + Double(parsedCreatedAt)
    }
}
