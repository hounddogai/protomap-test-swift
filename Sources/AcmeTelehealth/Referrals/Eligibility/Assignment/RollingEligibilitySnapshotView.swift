import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a rolling eligibility snapshot.
    final class RollingEligibilitySnapshotView {
        var code: String
        var nameText: String
        var checksumText: String
        var patientRef: String
        var sourceText: String
        var amount: String
        var statusLabel: String

        init(code: String, nameText: String, checksumText: String, patientRef: String, sourceText: String, amount: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.checksumText = checksumText
            self.patientRef = patientRef
            self.sourceText = sourceText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toRollingEligibilitySnapshotView(_ item: RollingEligibilitySnapshot) -> RollingEligibilitySnapshotView {
        return RollingEligibilitySnapshotView(
            code: item.code,
            nameText: item.name,
            checksumText: item.checksum,
            patientRef: item.patientRef,
            sourceText: item.source,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingEligibilitySnapshotViews(_ items: [RollingEligibilitySnapshot]) -> [RollingEligibilitySnapshotView] {
        var views: [RollingEligibilitySnapshotView] = []
        for item in items {
            views.append(toRollingEligibilitySnapshotView(item))
        }
        return views
    }

    static func sumRollingEligibilitySnapshotView(_ view: RollingEligibilitySnapshotView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
