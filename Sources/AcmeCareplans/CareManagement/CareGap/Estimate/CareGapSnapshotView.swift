import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap snapshot.
    final class CareGapSnapshotView {
        var codeText: String
        var name: String
        var procedureCode: String
        var segmentText: String
        var encounterID: String
        var clinicianID: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, name: String, procedureCode: String, segmentText: String, encounterID: String, clinicianID: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.procedureCode = procedureCode
            self.segmentText = segmentText
            self.encounterID = encounterID
            self.clinicianID = clinicianID
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapSnapshotView(_ item: CareGapSnapshot) -> CareGapSnapshotView {
        return CareGapSnapshotView(
            codeText: item.code,
            name: item.name,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            segmentText: item.segment,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            clinicianID: item.clinicianID,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapSnapshotViews(_ items: [CareGapSnapshot]) -> [CareGapSnapshotView] {
        var views: [CareGapSnapshotView] = []
        for item in items {
            views.append(toCareGapSnapshotView(item))
        }
        return views
    }

    static func sumCareGapSnapshotView(_ view: CareGapSnapshotView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
