import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance manifest.
    final class RemittanceManifestView {
        var code: String
        var labelText: String
        var currency: String
        var approved: String
        var reviewer: String
        var updatedAt: String
        var capacity: String
        var quantity: String
        var weightText: String
        var encounterIDText: String
        var statusLabel: String

        init(code: String, labelText: String, currency: String, approved: String, reviewer: String, updatedAt: String, capacity: String, quantity: String, weightText: String, encounterIDText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.currency = currency
            self.approved = approved
            self.reviewer = reviewer
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.quantity = quantity
            self.weightText = weightText
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceManifestView(_ item: RemittanceManifest) -> RemittanceManifestView {
        return RemittanceManifestView(
            code: item.code,
            labelText: item.label,
            currency: item.currency,
            approved: "\(item.approved)",
            reviewer: item.reviewer,
            updatedAt: String(item.updatedAt),
            capacity: String(item.capacity),
            quantity: String(item.quantity),
            weightText: String(format: "%.2f", item.weight),
            encounterIDText: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceManifestViews(_ items: [RemittanceManifest]) -> [RemittanceManifestView] {
        var views: [RemittanceManifestView] = []
        for item in items {
            views.append(toRemittanceManifestView(item))
        }
        return views
    }

    static func sumRemittanceManifestView(_ view: RemittanceManifestView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedCapacity) + Double(parsedQuantity)
    }
}
