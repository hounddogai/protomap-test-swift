import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary acuity plan snapshot.
    final class PrimaryAcuityPlanSnapshotView {
        var codeText: String
        var label: String
        var diagnosisCode: String
        var archived: String
        var patientRef: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, label: String, diagnosisCode: String, archived: String, patientRef: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.patientRef = patientRef
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryAcuityPlanSnapshotView(_ item: PrimaryAcuityPlanSnapshot) -> PrimaryAcuityPlanSnapshotView {
        return PrimaryAcuityPlanSnapshotView(
            codeText: item.code,
            label: item.label,
            diagnosisCode: item.diagnosisCode,
            archived: "\(item.archived)",
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryAcuityPlanSnapshotViews(_ items: [PrimaryAcuityPlanSnapshot]) -> [PrimaryAcuityPlanSnapshotView] {
        var views: [PrimaryAcuityPlanSnapshotView] = []
        for item in items {
            views.append(toPrimaryAcuityPlanSnapshotView(item))
        }
        return views
    }

    static func sumPrimaryAcuityPlanSnapshotView(_ view: PrimaryAcuityPlanSnapshotView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
