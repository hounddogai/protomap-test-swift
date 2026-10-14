import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive claim target.
    final class AdaptiveClaimTargetView {
        var code: String
        var name: String
        var discount: String
        var maximum: String
        var description: String
        var createdAtText: String
        var statusLabel: String

        init(code: String, name: String, discount: String, maximum: String, description: String, createdAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.discount = discount
            self.maximum = maximum
            self.description = description
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveClaimTargetView(_ item: AdaptiveClaimTarget) -> AdaptiveClaimTargetView {
        return AdaptiveClaimTargetView(
            code: item.code,
            name: item.name,
            discount: String(format: "%.2f", item.discount),
            maximum: String(format: "%.2f", item.maximum),
            description: item.description,
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveClaimTargetViews(_ items: [AdaptiveClaimTarget]) -> [AdaptiveClaimTargetView] {
        var views: [AdaptiveClaimTargetView] = []
        for item in items {
            views.append(toAdaptiveClaimTargetView(item))
        }
        return views
    }

    static func sumAdaptiveClaimTargetView(_ view: AdaptiveClaimTargetView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedDiscount + parsedMaximum + Double(parsedCreatedAt)
    }
}
