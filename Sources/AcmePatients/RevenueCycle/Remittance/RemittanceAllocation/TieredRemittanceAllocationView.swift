import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered remittance allocation.
    final class TieredRemittanceAllocationView {
        var codeText: String
        var label: String
        var checksumText: String
        var capacityText: String
        var categoryText: String
        var startsAt: String
        var region: String
        var cost: String
        var statusLabel: String

        init(codeText: String, label: String, checksumText: String, capacityText: String, categoryText: String, startsAt: String, region: String, cost: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.checksumText = checksumText
            self.capacityText = capacityText
            self.categoryText = categoryText
            self.startsAt = startsAt
            self.region = region
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRemittanceAllocationView(_ item: TieredRemittanceAllocation) -> TieredRemittanceAllocationView {
        return TieredRemittanceAllocationView(
            codeText: item.code,
            label: item.label,
            checksumText: item.checksum,
            capacityText: String(item.capacity),
            categoryText: item.category,
            startsAt: String(item.startsAt),
            region: Kit.Text.truncate(item.region, limit: 120),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRemittanceAllocationViews(_ items: [TieredRemittanceAllocation]) -> [TieredRemittanceAllocationView] {
        var views: [TieredRemittanceAllocationView] = []
        for item in items {
            views.append(toTieredRemittanceAllocationView(item))
        }
        return views
    }

    static func sumTieredRemittanceAllocationView(_ view: TieredRemittanceAllocationView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedCapacity) + Double(parsedStartsAt) + parsedCost
    }
}
