import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory snapshot.
    final class InventorySnapshotView {
        var code: String
        var label: String
        var ownerID: String
        var attempts: String
        var facility: String
        var diagnosisCode: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, label: String, ownerID: String, attempts: String, facility: String, diagnosisCode: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.attempts = attempts
            self.facility = facility
            self.diagnosisCode = diagnosisCode
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toInventorySnapshotView(_ item: InventorySnapshot) -> InventorySnapshotView {
        return InventorySnapshotView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            ownerID: item.ownerID,
            attempts: String(item.attempts),
            facility: Kit.Text.truncate(item.facility, limit: 120),
            diagnosisCode: item.diagnosisCode,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventorySnapshotViews(_ items: [InventorySnapshot]) -> [InventorySnapshotView] {
        var views: [InventorySnapshotView] = []
        for item in items {
            views.append(toInventorySnapshotView(item))
        }
        return views
    }

    static func sumInventorySnapshotView(_ view: InventorySnapshotView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
