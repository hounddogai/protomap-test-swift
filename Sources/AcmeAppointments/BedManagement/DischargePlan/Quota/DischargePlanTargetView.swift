import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan target.
    final class DischargePlanTargetView {
        var code: String
        var name: String
        var margin: String
        var facility: String
        var region: String
        var ceiling: String
        var statusLabel: String

        init(code: String, name: String, margin: String, facility: String, region: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.margin = margin
            self.facility = facility
            self.region = region
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanTargetView(_ item: DischargePlanTarget) -> DischargePlanTargetView {
        return DischargePlanTargetView(
            code: item.code,
            name: item.name,
            margin: String(format: "%.2f", item.margin),
            facility: item.facility,
            region: Kit.Text.truncate(item.region, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanTargetViews(_ items: [DischargePlanTarget]) -> [DischargePlanTargetView] {
        var views: [DischargePlanTargetView] = []
        for item in items {
            views.append(toDischargePlanTargetView(item))
        }
        return views
    }

    static func sumDischargePlanTargetView(_ view: DischargePlanTargetView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedMargin + parsedCeiling
    }
}
