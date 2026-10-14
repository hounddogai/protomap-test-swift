import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient charge tier.
    final class LenientChargeTierView {
        var code: String
        var label: String
        var versionText: String
        var externalRef: String
        var encounterIDText: String
        var quantity: String
        var active: String
        var updatedAtText: String
        var ceiling: String
        var revision: String
        var statusLabel: String

        init(code: String, label: String, versionText: String, externalRef: String, encounterIDText: String, quantity: String, active: String, updatedAtText: String, ceiling: String, revision: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.versionText = versionText
            self.externalRef = externalRef
            self.encounterIDText = encounterIDText
            self.quantity = quantity
            self.active = active
            self.updatedAtText = updatedAtText
            self.ceiling = ceiling
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toLenientChargeTierView(_ item: LenientChargeTier) -> LenientChargeTierView {
        return LenientChargeTierView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            versionText: String(item.version),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            encounterIDText: item.encounterID,
            quantity: String(item.quantity),
            active: "\(item.active)",
            updatedAtText: String(item.updatedAt),
            ceiling: String(format: "%.2f", item.ceiling),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientChargeTierViews(_ items: [LenientChargeTier]) -> [LenientChargeTierView] {
        var views: [LenientChargeTierView] = []
        for item in items {
            views.append(toLenientChargeTierView(item))
        }
        return views
    }

    static func sumLenientChargeTierView(_ view: LenientChargeTierView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedVersion) + Double(parsedQuantity) + Double(parsedUpdatedAt)
    }
}
