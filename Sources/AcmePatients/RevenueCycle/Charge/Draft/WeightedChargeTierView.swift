import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a weighted charge tier.
    final class WeightedChargeTierView {
        var code: String
        var name: String
        var facility: String
        var visitMinutes: String
        var attemptsText: String
        var statusLabel: String

        init(code: String, name: String, facility: String, visitMinutes: String, attemptsText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.facility = facility
            self.visitMinutes = visitMinutes
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedChargeTierView(_ item: WeightedChargeTier) -> WeightedChargeTierView {
        return WeightedChargeTierView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            facility: Kit.Text.truncate(item.facility, limit: 120),
            visitMinutes: String(item.visitMinutes),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedChargeTierViews(_ items: [WeightedChargeTier]) -> [WeightedChargeTierView] {
        var views: [WeightedChargeTierView] = []
        for item in items {
            views.append(toWeightedChargeTierView(item))
        }
        return views
    }

    static func sumWeightedChargeTierView(_ view: WeightedChargeTierView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedAttempts)
    }
}
