import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility snapshot.
    final class EligibilitySnapshotView {
        var codeText: String
        var labelText: String
        var nameText: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, labelText: String, nameText: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.nameText = nameText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilitySnapshotView(_ item: EligibilitySnapshot) -> EligibilitySnapshotView {
        return EligibilitySnapshotView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            nameText: item.name,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilitySnapshotViews(_ items: [EligibilitySnapshot]) -> [EligibilitySnapshotView] {
        var views: [EligibilitySnapshotView] = []
        for item in items {
            views.append(toEligibilitySnapshotView(item))
        }
        return views
    }

    static func sumEligibilitySnapshotView(_ view: EligibilitySnapshotView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
