import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient authorization digest.
    final class LenientAuthorizationDigestView {
        var codeText: String
        var label: String
        var quantity: String
        var batchSizeText: String
        var expiresAtText: String
        var patientRefText: String
        var name: String
        var limitText: String
        var title: String
        var statusLabel: String

        init(codeText: String, label: String, quantity: String, batchSizeText: String, expiresAtText: String, patientRefText: String, name: String, limitText: String, title: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.quantity = quantity
            self.batchSizeText = batchSizeText
            self.expiresAtText = expiresAtText
            self.patientRefText = patientRefText
            self.name = name
            self.limitText = limitText
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toLenientAuthorizationDigestView(_ item: LenientAuthorizationDigest) -> LenientAuthorizationDigestView {
        return LenientAuthorizationDigestView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 40),
            quantity: String(item.quantity),
            batchSizeText: String(item.batchSize),
            expiresAtText: String(item.expiresAt),
            patientRefText: item.patientRef,
            name: item.name,
            limitText: String(item.limit),
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientAuthorizationDigestViews(_ items: [LenientAuthorizationDigest]) -> [LenientAuthorizationDigestView] {
        var views: [LenientAuthorizationDigestView] = []
        for item in items {
            views.append(toLenientAuthorizationDigestView(item))
        }
        return views
    }

    static func sumLenientAuthorizationDigestView(_ view: LenientAuthorizationDigestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedQuantity) + Double(parsedBatchSize) + Double(parsedExpiresAt)
    }
}
