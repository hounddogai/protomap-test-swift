import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness tier.
    final class WitnessTierView {
        var code: String
        var nameText: String
        var ceiling: String
        var unit: String
        var bed: String
        var phoneText: String
        var cost: String
        var statusLabel: String

        init(code: String, nameText: String, ceiling: String, unit: String, bed: String, phoneText: String, cost: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ceiling = ceiling
            self.unit = unit
            self.bed = bed
            self.phoneText = phoneText
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessTierView(_ item: WitnessTier) -> WitnessTierView {
        return WitnessTierView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            unit: item.unit,
            bed: item.bed,
            phoneText: Kit.Text.truncate(item.phone, limit: 64),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessTierViews(_ items: [WitnessTier]) -> [WitnessTierView] {
        var views: [WitnessTierView] = []
        for item in items {
            views.append(toWitnessTierView(item))
        }
        return views
    }

    static func sumWitnessTierView(_ view: WitnessTierView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCeiling + parsedCost
    }
}
