import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a weighted claim override.
    final class WeightedClaimOverrideView {
        var code: String
        var nameText: String
        var refills: String
        var batchSize: String
        var country: String
        var statusLabel: String

        init(code: String, nameText: String, refills: String, batchSize: String, country: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.refills = refills
            self.batchSize = batchSize
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedClaimOverrideView(_ item: WeightedClaimOverride) -> WeightedClaimOverrideView {
        return WeightedClaimOverrideView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            refills: String(item.refills),
            batchSize: String(item.batchSize),
            country: Kit.Text.truncate(item.country, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedClaimOverrideViews(_ items: [WeightedClaimOverride]) -> [WeightedClaimOverrideView] {
        var views: [WeightedClaimOverrideView] = []
        for item in items {
            views.append(toWeightedClaimOverrideView(item))
        }
        return views
    }

    static func sumWeightedClaimOverrideView(_ view: WeightedClaimOverrideView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedRefills) + Double(parsedBatchSize)
    }
}
