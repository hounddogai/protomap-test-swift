import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding checkpoint.
    final class RoundingCheckpointView {
        var codeText: String
        var label: String
        var rateText: String
        var procedureCodeText: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(codeText: String, label: String, rateText: String, procedureCodeText: String, diagnosisCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.rateText = rateText
            self.procedureCodeText = procedureCodeText
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingCheckpointView(_ item: RoundingCheckpoint) -> RoundingCheckpointView {
        return RoundingCheckpointView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            rateText: String(format: "%.2f", item.rate),
            procedureCodeText: item.procedureCode,
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingCheckpointViews(_ items: [RoundingCheckpoint]) -> [RoundingCheckpointView] {
        var views: [RoundingCheckpointView] = []
        for item in items {
            views.append(toRoundingCheckpointView(item))
        }
        return views
    }

    static func sumRoundingCheckpointView(_ view: RoundingCheckpointView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
