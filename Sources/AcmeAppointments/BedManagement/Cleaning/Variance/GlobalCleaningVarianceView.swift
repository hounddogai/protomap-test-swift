import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global cleaning variance.
    final class GlobalCleaningVarianceView {
        var code: String
        var label: String
        var createdAtText: String
        var country: String
        var refills: String
        var cost: String
        var floorValue: String
        var statusLabel: String

        init(code: String, label: String, createdAtText: String, country: String, refills: String, cost: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAtText = createdAtText
            self.country = country
            self.refills = refills
            self.cost = cost
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCleaningVarianceView(_ item: GlobalCleaningVariance) -> GlobalCleaningVarianceView {
        return GlobalCleaningVarianceView(
            code: item.code,
            label: item.label,
            createdAtText: String(item.createdAt),
            country: item.country,
            refills: String(item.refills),
            cost: String(format: "%.2f", item.cost),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCleaningVarianceViews(_ items: [GlobalCleaningVariance]) -> [GlobalCleaningVarianceView] {
        var views: [GlobalCleaningVarianceView] = []
        for item in items {
            views.append(toGlobalCleaningVarianceView(item))
        }
        return views
    }

    static func sumGlobalCleaningVarianceView(_ view: GlobalCleaningVarianceView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedRefills) + parsedCost
    }
}
