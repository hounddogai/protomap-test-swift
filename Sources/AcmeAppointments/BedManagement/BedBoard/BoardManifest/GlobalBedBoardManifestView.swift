import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global bed board manifest.
    final class GlobalBedBoardManifestView {
        var code: String
        var label: String
        var ownerIDText: String
        var cost: String
        var expiresAtText: String
        var quantityText: String
        var refills: String
        var sequence: String
        var statusLabel: String

        init(code: String, label: String, ownerIDText: String, cost: String, expiresAtText: String, quantityText: String, refills: String, sequence: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ownerIDText = ownerIDText
            self.cost = cost
            self.expiresAtText = expiresAtText
            self.quantityText = quantityText
            self.refills = refills
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalBedBoardManifestView(_ item: GlobalBedBoardManifest) -> GlobalBedBoardManifestView {
        return GlobalBedBoardManifestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 40),
            ownerIDText: item.ownerID,
            cost: String(format: "%.2f", item.cost),
            expiresAtText: String(item.expiresAt),
            quantityText: String(item.quantity),
            refills: String(item.refills),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalBedBoardManifestViews(_ items: [GlobalBedBoardManifest]) -> [GlobalBedBoardManifestView] {
        var views: [GlobalBedBoardManifestView] = []
        for item in items {
            views.append(toGlobalBedBoardManifestView(item))
        }
        return views
    }

    static func sumGlobalBedBoardManifestView(_ view: GlobalBedBoardManifestView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedCost + Double(parsedExpiresAt) + Double(parsedQuantity)
    }
}
