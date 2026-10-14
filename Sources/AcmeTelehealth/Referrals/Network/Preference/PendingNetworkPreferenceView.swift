import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending network preference.
    final class PendingNetworkPreferenceView {
        var code: String
        var title: String
        var capacityText: String
        var cost: String
        var attempts: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, capacityText: String, cost: String, attempts: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.capacityText = capacityText
            self.cost = cost
            self.attempts = attempts
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toPendingNetworkPreferenceView(_ item: PendingNetworkPreference) -> PendingNetworkPreferenceView {
        return PendingNetworkPreferenceView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            capacityText: String(item.capacity),
            cost: String(format: "%.2f", item.cost),
            attempts: String(item.attempts),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingNetworkPreferenceViews(_ items: [PendingNetworkPreference]) -> [PendingNetworkPreferenceView] {
        var views: [PendingNetworkPreferenceView] = []
        for item in items {
            views.append(toPendingNetworkPreferenceView(item))
        }
        return views
    }

    static func sumPendingNetworkPreferenceView(_ view: PendingNetworkPreferenceView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedCapacity) + parsedCost + Double(parsedAttempts)
    }
}
