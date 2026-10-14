import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient eligibility snapshot.
    final class LenientEligibilitySnapshotView {
        var codeText: String
        var label: String
        var copay: String
        var name: String
        var discount: String
        var statusLabel: String

        init(codeText: String, label: String, copay: String, name: String, discount: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.copay = copay
            self.name = name
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toLenientEligibilitySnapshotView(_ item: LenientEligibilitySnapshot) -> LenientEligibilitySnapshotView {
        return LenientEligibilitySnapshotView(
            codeText: item.code,
            label: item.label,
            copay: String(format: "%.2f", item.copay),
            name: item.name,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientEligibilitySnapshotViews(_ items: [LenientEligibilitySnapshot]) -> [LenientEligibilitySnapshotView] {
        var views: [LenientEligibilitySnapshotView] = []
        for item in items {
            views.append(toLenientEligibilitySnapshotView(item))
        }
        return views
    }

    static func sumLenientEligibilitySnapshotView(_ view: LenientEligibilitySnapshotView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedCopay + parsedDiscount
    }
}
