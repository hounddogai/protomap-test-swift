import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score checkpoint.
    final class RiskScoreCheckpointView {
        var code: String
        var labelText: String
        var payerText: String
        var description: String
        var ceiling: String
        var revision: String
        var patientRef: String
        var statusLabel: String

        init(code: String, labelText: String, payerText: String, description: String, ceiling: String, revision: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.payerText = payerText
            self.description = description
            self.ceiling = ceiling
            self.revision = revision
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreCheckpointView(_ item: RiskScoreCheckpoint) -> RiskScoreCheckpointView {
        return RiskScoreCheckpointView(
            code: item.code,
            labelText: item.label,
            payerText: item.payer,
            description: item.description,
            ceiling: String(format: "%.2f", item.ceiling),
            revision: String(item.revision),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreCheckpointViews(_ items: [RiskScoreCheckpoint]) -> [RiskScoreCheckpointView] {
        var views: [RiskScoreCheckpointView] = []
        for item in items {
            views.append(toRiskScoreCheckpointView(item))
        }
        return views
    }

    static func sumRiskScoreCheckpointView(_ view: RiskScoreCheckpointView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedCeiling + Double(parsedRevision)
    }
}
