import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive inventory audit.
    final class AdaptiveInventoryAuditView {
        var codeText: String
        var name: String
        var summary: String
        var endsAt: String
        var costText: String
        var weight: String
        var ceiling: String
        var acuity: String
        var ward: String
        var batchSize: String
        var statusLabel: String

        init(codeText: String, name: String, summary: String, endsAt: String, costText: String, weight: String, ceiling: String, acuity: String, ward: String, batchSize: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.summary = summary
            self.endsAt = endsAt
            self.costText = costText
            self.weight = weight
            self.ceiling = ceiling
            self.acuity = acuity
            self.ward = ward
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveInventoryAuditView(_ item: AdaptiveInventoryAudit) -> AdaptiveInventoryAuditView {
        return AdaptiveInventoryAuditView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            summary: item.summary,
            endsAt: String(item.endsAt),
            costText: String(format: "%.2f", item.cost),
            weight: String(format: "%.2f", item.weight),
            ceiling: String(format: "%.2f", item.ceiling),
            acuity: String(item.acuity),
            ward: Kit.Text.truncate(item.ward, limit: 120),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveInventoryAuditViews(_ items: [AdaptiveInventoryAudit]) -> [AdaptiveInventoryAuditView] {
        var views: [AdaptiveInventoryAuditView] = []
        for item in items {
            views.append(toAdaptiveInventoryAuditView(item))
        }
        return views
    }

    static func sumAdaptiveInventoryAuditView(_ view: AdaptiveInventoryAuditView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedEndsAt) + parsedCost + parsedWeight
    }
}
