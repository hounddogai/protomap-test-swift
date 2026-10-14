import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a primary slot rollup.
    final class PrimarySlotRollupView {
        var code: String
        var name: String
        var attempts: String
        var updatedAt: String
        var ceiling: String
        var discount: String
        var maximum: String
        var statusLabel: String

        init(code: String, name: String, attempts: String, updatedAt: String, ceiling: String, discount: String, maximum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.discount = discount
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toPrimarySlotRollupView(_ item: PrimarySlotRollup) -> PrimarySlotRollupView {
        return PrimarySlotRollupView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            attempts: String(item.attempts),
            updatedAt: String(item.updatedAt),
            ceiling: String(format: "%.2f", item.ceiling),
            discount: String(format: "%.2f", item.discount),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimarySlotRollupViews(_ items: [PrimarySlotRollup]) -> [PrimarySlotRollupView] {
        var views: [PrimarySlotRollupView] = []
        for item in items {
            views.append(toPrimarySlotRollupView(item))
        }
        return views
    }

    static func sumPrimarySlotRollupView(_ view: PrimarySlotRollupView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedAttempts) + Double(parsedUpdatedAt) + parsedCeiling
    }
}
