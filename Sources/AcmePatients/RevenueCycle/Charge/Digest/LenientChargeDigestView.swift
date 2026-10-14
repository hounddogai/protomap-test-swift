import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient charge digest.
    final class LenientChargeDigestView {
        var codeText: String
        var label: String
        var externalRef: String
        var ownerIDText: String
        var category: String
        var diagnosisCode: String
        var discountText: String
        var statusLabel: String

        init(codeText: String, label: String, externalRef: String, ownerIDText: String, category: String, diagnosisCode: String, discountText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.externalRef = externalRef
            self.ownerIDText = ownerIDText
            self.category = category
            self.diagnosisCode = diagnosisCode
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientChargeDigestView(_ item: LenientChargeDigest) -> LenientChargeDigestView {
        return LenientChargeDigestView(
            codeText: item.code,
            label: item.label,
            externalRef: item.externalRef,
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 64),
            category: item.category,
            diagnosisCode: item.diagnosisCode,
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientChargeDigestViews(_ items: [LenientChargeDigest]) -> [LenientChargeDigestView] {
        var views: [LenientChargeDigestView] = []
        for item in items {
            views.append(toLenientChargeDigestView(item))
        }
        return views
    }

    static func sumLenientChargeDigestView(_ view: LenientChargeDigestView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedDiscount
    }
}
