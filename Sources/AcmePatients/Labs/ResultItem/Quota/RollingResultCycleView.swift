import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling result cycle.
    final class RollingResultCycleView {
        var code: String
        var title: String
        var ward: String
        var createdAtText: String
        var copay: String
        var costText: String
        var weightText: String
        var version: String
        var description: String
        var refills: String
        var statusLabel: String

        init(code: String, title: String, ward: String, createdAtText: String, copay: String, costText: String, weightText: String, version: String, description: String, refills: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ward = ward
            self.createdAtText = createdAtText
            self.copay = copay
            self.costText = costText
            self.weightText = weightText
            self.version = version
            self.description = description
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toRollingResultCycleView(_ item: RollingResultCycle) -> RollingResultCycleView {
        return RollingResultCycleView(
            code: item.code,
            title: item.title,
            ward: item.ward,
            createdAtText: String(item.createdAt),
            copay: String(format: "%.2f", item.copay),
            costText: String(format: "%.2f", item.cost),
            weightText: String(format: "%.2f", item.weight),
            version: String(item.version),
            description: item.description,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingResultCycleViews(_ items: [RollingResultCycle]) -> [RollingResultCycleView] {
        var views: [RollingResultCycleView] = []
        for item in items {
            views.append(toRollingResultCycleView(item))
        }
        return views
    }

    static func sumRollingResultCycleView(_ view: RollingResultCycleView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedCreatedAt) + parsedCopay + parsedCost
    }
}
