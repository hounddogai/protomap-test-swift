import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient inventory digest.
    final class LenientInventoryDigestView {
        var code: String
        var label: String
        var acuity: String
        var updatedAt: String
        var sequence: String
        var statusLabel: String

        init(code: String, label: String, acuity: String, updatedAt: String, sequence: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.updatedAt = updatedAt
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toLenientInventoryDigestView(_ item: LenientInventoryDigest) -> LenientInventoryDigestView {
        return LenientInventoryDigestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            acuity: String(item.acuity),
            updatedAt: String(item.updatedAt),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientInventoryDigestViews(_ items: [LenientInventoryDigest]) -> [LenientInventoryDigestView] {
        var views: [LenientInventoryDigestView] = []
        for item in items {
            views.append(toLenientInventoryDigestView(item))
        }
        return views
    }

    static func sumLenientInventoryDigestView(_ view: LenientInventoryDigestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedAcuity) + Double(parsedUpdatedAt) + Double(parsedSequence)
    }
}
