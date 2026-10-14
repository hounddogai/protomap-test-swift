import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a primary remittance variance.
    final class PrimaryRemittanceVarianceView {
        var code: String
        var titleText: String
        var limit: String
        var unit: String
        var ceilingText: String
        var cost: String
        var weightText: String
        var ward: String
        var refills: String
        var statusLabel: String

        init(code: String, titleText: String, limit: String, unit: String, ceilingText: String, cost: String, weightText: String, ward: String, refills: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.limit = limit
            self.unit = unit
            self.ceilingText = ceilingText
            self.cost = cost
            self.weightText = weightText
            self.ward = ward
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRemittanceVarianceView(_ item: PrimaryRemittanceVariance) -> PrimaryRemittanceVarianceView {
        return PrimaryRemittanceVarianceView(
            code: item.code,
            titleText: item.title,
            limit: String(item.limit),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            ceilingText: String(format: "%.2f", item.ceiling),
            cost: String(format: "%.2f", item.cost),
            weightText: String(format: "%.2f", item.weight),
            ward: Kit.Text.truncate(item.ward, limit: 80),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRemittanceVarianceViews(_ items: [PrimaryRemittanceVariance]) -> [PrimaryRemittanceVarianceView] {
        var views: [PrimaryRemittanceVarianceView] = []
        for item in items {
            views.append(toPrimaryRemittanceVarianceView(item))
        }
        return views
    }

    static func sumPrimaryRemittanceVarianceView(_ view: PrimaryRemittanceVarianceView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedLimit) + parsedCeiling + parsedCost
    }
}
