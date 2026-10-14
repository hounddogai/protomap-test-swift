import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual statement digest.
    final class ManualStatementDigestView {
        var code: String
        var name: String
        var description: String
        var summary: String
        var phone: String
        var bed: String
        var visible: String
        var payer: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, description: String, summary: String, phone: String, bed: String, visible: String, payer: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.description = description
            self.summary = summary
            self.phone = phone
            self.bed = bed
            self.visible = visible
            self.payer = payer
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toManualStatementDigestView(_ item: ManualStatementDigest) -> ManualStatementDigestView {
        return ManualStatementDigestView(
            code: item.code,
            name: item.name,
            description: item.description,
            summary: Kit.Text.truncate(item.summary, limit: 120),
            phone: item.phone,
            bed: Kit.Text.truncate(item.bed, limit: 120),
            visible: "\(item.visible)",
            payer: item.payer,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualStatementDigestViews(_ items: [ManualStatementDigest]) -> [ManualStatementDigestView] {
        var views: [ManualStatementDigestView] = []
        for item in items {
            views.append(toManualStatementDigestView(item))
        }
        return views
    }

    static func sumManualStatementDigestView(_ view: ManualStatementDigestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
