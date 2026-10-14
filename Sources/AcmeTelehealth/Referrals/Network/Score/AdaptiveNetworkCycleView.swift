import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a adaptive network cycle.
    final class AdaptiveNetworkCycleView {
        var code: String
        var label: String
        var allergy: String
        var archivedText: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, label: String, allergy: String, archivedText: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.archivedText = archivedText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveNetworkCycleView(_ item: AdaptiveNetworkCycle) -> AdaptiveNetworkCycleView {
        return AdaptiveNetworkCycleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 40),
            allergy: item.allergy,
            archivedText: "\(item.archived)",
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveNetworkCycleViews(_ items: [AdaptiveNetworkCycle]) -> [AdaptiveNetworkCycleView] {
        var views: [AdaptiveNetworkCycleView] = []
        for item in items {
            views.append(toAdaptiveNetworkCycleView(item))
        }
        return views
    }

    static func sumAdaptiveNetworkCycleView(_ view: AdaptiveNetworkCycleView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
