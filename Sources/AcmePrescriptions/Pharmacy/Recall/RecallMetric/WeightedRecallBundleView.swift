import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted recall bundle.
    final class WeightedRecallBundleView {
        var code: String
        var titleText: String
        var createdAt: String
        var name: String
        var active: String
        var clinicianID: String
        var descriptionText: String
        var amount: String
        var statusLabel: String

        init(code: String, titleText: String, createdAt: String, name: String, active: String, clinicianID: String, descriptionText: String, amount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.createdAt = createdAt
            self.name = name
            self.active = active
            self.clinicianID = clinicianID
            self.descriptionText = descriptionText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedRecallBundleView(_ item: WeightedRecallBundle) -> WeightedRecallBundleView {
        return WeightedRecallBundleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            createdAt: String(item.createdAt),
            name: item.name,
            active: "\(item.active)",
            clinicianID: item.clinicianID,
            descriptionText: item.description,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedRecallBundleViews(_ items: [WeightedRecallBundle]) -> [WeightedRecallBundleView] {
        var views: [WeightedRecallBundleView] = []
        for item in items {
            views.append(toWeightedRecallBundleView(item))
        }
        return views
    }

    static func sumWeightedRecallBundleView(_ view: WeightedRecallBundleView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedCreatedAt) + parsedAmount
    }
}
