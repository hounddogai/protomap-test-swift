import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure checkpoint.
    final class ClosureCheckpointView {
        var code: String
        var labelText: String
        var windowDays: String
        var revisionText: String
        var batchSize: String
        var diagnosisCode: String
        var expiresAt: String
        var phone: String
        var patientRef: String
        var statusLabel: String

        init(code: String, labelText: String, windowDays: String, revisionText: String, batchSize: String, diagnosisCode: String, expiresAt: String, phone: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.windowDays = windowDays
            self.revisionText = revisionText
            self.batchSize = batchSize
            self.diagnosisCode = diagnosisCode
            self.expiresAt = expiresAt
            self.phone = phone
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toClosureCheckpointView(_ item: ClosureCheckpoint) -> ClosureCheckpointView {
        return ClosureCheckpointView(
            code: item.code,
            labelText: item.label,
            windowDays: String(item.windowDays),
            revisionText: String(item.revision),
            batchSize: String(item.batchSize),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            expiresAt: String(item.expiresAt),
            phone: item.phone,
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureCheckpointViews(_ items: [ClosureCheckpoint]) -> [ClosureCheckpointView] {
        var views: [ClosureCheckpointView] = []
        for item in items {
            views.append(toClosureCheckpointView(item))
        }
        return views
    }

    static func sumClosureCheckpointView(_ view: ClosureCheckpointView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedRevision) + Double(parsedBatchSize)
    }
}
