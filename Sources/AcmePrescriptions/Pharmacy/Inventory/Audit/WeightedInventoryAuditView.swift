import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted inventory audit.
    final class WeightedInventoryAuditView {
        var code: String
        var name: String
        var label: String
        var quantity: String
        var specialtyText: String
        var facilityText: String
        var encounterIDText: String
        var retries: String
        var contactEmail: String
        var discount: String
        var channel: String
        var statusLabel: String

        init(code: String, name: String, label: String, quantity: String, specialtyText: String, facilityText: String, encounterIDText: String, retries: String, contactEmail: String, discount: String, channel: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.label = label
            self.quantity = quantity
            self.specialtyText = specialtyText
            self.facilityText = facilityText
            self.encounterIDText = encounterIDText
            self.retries = retries
            self.contactEmail = contactEmail
            self.discount = discount
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedInventoryAuditView(_ item: WeightedInventoryAudit) -> WeightedInventoryAuditView {
        return WeightedInventoryAuditView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            label: item.label,
            quantity: String(item.quantity),
            specialtyText: item.specialty,
            facilityText: item.facility,
            encounterIDText: item.encounterID,
            retries: String(item.retries),
            contactEmail: item.contactEmail,
            discount: String(format: "%.2f", item.discount),
            channel: Kit.Text.truncate(item.channel, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedInventoryAuditViews(_ items: [WeightedInventoryAudit]) -> [WeightedInventoryAuditView] {
        var views: [WeightedInventoryAuditView] = []
        for item in items {
            views.append(toWeightedInventoryAuditView(item))
        }
        return views
    }

    static func sumWeightedInventoryAuditView(_ view: WeightedInventoryAuditView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedQuantity) + Double(parsedRetries) + parsedDiscount
    }
}
