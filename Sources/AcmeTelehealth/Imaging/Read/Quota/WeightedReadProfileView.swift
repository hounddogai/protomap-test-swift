import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted read profile.
    final class WeightedReadProfileView {
        var code: String
        var name: String
        var categoryText: String
        var rateText: String
        var externalRef: String
        var statusLabel: String

        init(code: String, name: String, categoryText: String, rateText: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.categoryText = categoryText
            self.rateText = rateText
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedReadProfileView(_ item: WeightedReadProfile) -> WeightedReadProfileView {
        return WeightedReadProfileView(
            code: item.code,
            name: item.name,
            categoryText: item.category,
            rateText: String(format: "%.2f", item.rate),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedReadProfileViews(_ items: [WeightedReadProfile]) -> [WeightedReadProfileView] {
        var views: [WeightedReadProfileView] = []
        for item in items {
            views.append(toWeightedReadProfileView(item))
        }
        return views
    }

    static func sumWeightedReadProfileView(_ view: WeightedReadProfileView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
