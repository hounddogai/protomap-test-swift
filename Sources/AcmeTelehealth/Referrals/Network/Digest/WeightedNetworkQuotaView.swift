import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted network quota.
    final class WeightedNetworkQuotaView {
        var code: String
        var nameText: String
        var specialtyText: String
        var margin: String
        var checksum: String
        var bed: String
        var encounterID: String
        var capacityText: String
        var cost: String
        var summary: String
        var label: String
        var statusLabel: String

        init(code: String, nameText: String, specialtyText: String, margin: String, checksum: String, bed: String, encounterID: String, capacityText: String, cost: String, summary: String, label: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.specialtyText = specialtyText
            self.margin = margin
            self.checksum = checksum
            self.bed = bed
            self.encounterID = encounterID
            self.capacityText = capacityText
            self.cost = cost
            self.summary = summary
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedNetworkQuotaView(_ item: WeightedNetworkQuota) -> WeightedNetworkQuotaView {
        return WeightedNetworkQuotaView(
            code: item.code,
            nameText: item.name,
            specialtyText: item.specialty,
            margin: String(format: "%.2f", item.margin),
            checksum: item.checksum,
            bed: item.bed,
            encounterID: item.encounterID,
            capacityText: String(item.capacity),
            cost: String(format: "%.2f", item.cost),
            summary: Kit.Text.truncate(item.summary, limit: 64),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedNetworkQuotaViews(_ items: [WeightedNetworkQuota]) -> [WeightedNetworkQuotaView] {
        var views: [WeightedNetworkQuotaView] = []
        for item in items {
            views.append(toWeightedNetworkQuotaView(item))
        }
        return views
    }

    static func sumWeightedNetworkQuotaView(_ view: WeightedNetworkQuotaView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedMargin + Double(parsedCapacity) + parsedCost
    }
}
