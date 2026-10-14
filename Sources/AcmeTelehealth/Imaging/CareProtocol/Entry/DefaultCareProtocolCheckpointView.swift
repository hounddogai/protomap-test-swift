import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a default care protocol checkpoint.
    final class DefaultCareProtocolCheckpointView {
        var code: String
        var label: String
        var diagnosisCode: String
        var procedureCodeText: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, procedureCodeText: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.procedureCodeText = procedureCodeText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCareProtocolCheckpointView(_ item: DefaultCareProtocolCheckpoint) -> DefaultCareProtocolCheckpointView {
        return DefaultCareProtocolCheckpointView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            procedureCodeText: item.procedureCode,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCareProtocolCheckpointViews(_ items: [DefaultCareProtocolCheckpoint]) -> [DefaultCareProtocolCheckpointView] {
        var views: [DefaultCareProtocolCheckpointView] = []
        for item in items {
            views.append(toDefaultCareProtocolCheckpointView(item))
        }
        return views
    }

    static func sumDefaultCareProtocolCheckpointView(_ view: DefaultCareProtocolCheckpointView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
