import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional charge slot.
    final class RegionalChargeSlotView {
        var code: String
        var labelText: String
        var expiresAt: String
        var cost: String
        var localeText: String
        var ceiling: String
        var statusLabel: String

        init(code: String, labelText: String, expiresAt: String, cost: String, localeText: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.expiresAt = expiresAt
            self.cost = cost
            self.localeText = localeText
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalChargeSlotView(_ item: RegionalChargeSlot) -> RegionalChargeSlotView {
        return RegionalChargeSlotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            expiresAt: String(item.expiresAt),
            cost: String(format: "%.2f", item.cost),
            localeText: item.locale,
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalChargeSlotViews(_ items: [RegionalChargeSlot]) -> [RegionalChargeSlotView] {
        var views: [RegionalChargeSlotView] = []
        for item in items {
            views.append(toRegionalChargeSlotView(item))
        }
        return views
    }

    static func sumRegionalChargeSlotView(_ view: RegionalChargeSlotView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedExpiresAt) + parsedCost + parsedCeiling
    }
}
