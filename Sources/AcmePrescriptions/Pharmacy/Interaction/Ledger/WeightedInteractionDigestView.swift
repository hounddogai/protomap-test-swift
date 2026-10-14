import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted interaction digest.
    final class WeightedInteractionDigestView {
        var code: String
        var title: String
        var visible: String
        var nameText: String
        var budget: String
        var updatedAtText: String
        var weightText: String
        var statusLabel: String

        init(code: String, title: String, visible: String, nameText: String, budget: String, updatedAtText: String, weightText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visible = visible
            self.nameText = nameText
            self.budget = budget
            self.updatedAtText = updatedAtText
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedInteractionDigestView(_ item: WeightedInteractionDigest) -> WeightedInteractionDigestView {
        return WeightedInteractionDigestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            visible: "\(item.visible)",
            nameText: item.name,
            budget: String(format: "%.2f", item.budget),
            updatedAtText: String(item.updatedAt),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedInteractionDigestViews(_ items: [WeightedInteractionDigest]) -> [WeightedInteractionDigestView] {
        var views: [WeightedInteractionDigestView] = []
        for item in items {
            views.append(toWeightedInteractionDigestView(item))
        }
        return views
    }

    static func sumWeightedInteractionDigestView(_ view: WeightedInteractionDigestView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedBudget + Double(parsedUpdatedAt) + parsedWeight
    }
}
