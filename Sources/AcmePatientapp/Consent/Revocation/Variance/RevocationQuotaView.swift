import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation quota.
    final class RevocationQuotaView {
        var codeText: String
        var label: String
        var facility: String
        var threshold: String
        var quantity: String
        var specialtyText: String
        var ratio: String
        var margin: String
        var minimumText: String
        var amount: String
        var contactEmailText: String
        var statusLabel: String

        init(codeText: String, label: String, facility: String, threshold: String, quantity: String, specialtyText: String, ratio: String, margin: String, minimumText: String, amount: String, contactEmailText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.facility = facility
            self.threshold = threshold
            self.quantity = quantity
            self.specialtyText = specialtyText
            self.ratio = ratio
            self.margin = margin
            self.minimumText = minimumText
            self.amount = amount
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationQuotaView(_ item: RevocationQuota) -> RevocationQuotaView {
        return RevocationQuotaView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            facility: item.facility,
            threshold: String(format: "%.2f", item.threshold),
            quantity: String(item.quantity),
            specialtyText: item.specialty,
            ratio: String(format: "%.2f", item.ratio),
            margin: String(format: "%.2f", item.margin),
            minimumText: String(format: "%.2f", item.minimum),
            amount: String(format: "%.2f", item.amount),
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationQuotaViews(_ items: [RevocationQuota]) -> [RevocationQuotaView] {
        var views: [RevocationQuotaView] = []
        for item in items {
            views.append(toRevocationQuotaView(item))
        }
        return views
    }

    static func sumRevocationQuotaView(_ view: RevocationQuotaView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedThreshold + Double(parsedQuantity) + parsedRatio
    }
}
