import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling authorization snapshot.
    final class RollingAuthorizationSnapshotView {
        var codeText: String
        var name: String
        var visibleText: String
        var patientRef: String
        var archivedText: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, name: String, visibleText: String, patientRef: String, archivedText: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.visibleText = visibleText
            self.patientRef = patientRef
            self.archivedText = archivedText
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAuthorizationSnapshotView(_ item: RollingAuthorizationSnapshot) -> RollingAuthorizationSnapshotView {
        return RollingAuthorizationSnapshotView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            visibleText: "\(item.visible)",
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            archivedText: "\(item.archived)",
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAuthorizationSnapshotViews(_ items: [RollingAuthorizationSnapshot]) -> [RollingAuthorizationSnapshotView] {
        var views: [RollingAuthorizationSnapshotView] = []
        for item in items {
            views.append(toRollingAuthorizationSnapshotView(item))
        }
        return views
    }

    static func sumRollingAuthorizationSnapshotView(_ view: RollingAuthorizationSnapshotView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
