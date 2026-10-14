import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict alert checkpoint.
    final class StrictAlertCheckpointView {
        var code: String
        var nameText: String
        var procedureCode: String
        var scoreText: String
        var wardText: String
        var thresholdText: String
        var region: String
        var statusLabel: String

        init(code: String, nameText: String, procedureCode: String, scoreText: String, wardText: String, thresholdText: String, region: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.procedureCode = procedureCode
            self.scoreText = scoreText
            self.wardText = wardText
            self.thresholdText = thresholdText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAlertCheckpointView(_ item: StrictAlertCheckpoint) -> StrictAlertCheckpointView {
        return StrictAlertCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            procedureCode: item.procedureCode,
            scoreText: String(format: "%.2f", item.score),
            wardText: item.ward,
            thresholdText: String(format: "%.2f", item.threshold),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAlertCheckpointViews(_ items: [StrictAlertCheckpoint]) -> [StrictAlertCheckpointView] {
        var views: [StrictAlertCheckpointView] = []
        for item in items {
            views.append(toStrictAlertCheckpointView(item))
        }
        return views
    }

    static func sumStrictAlertCheckpointView(_ view: StrictAlertCheckpointView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedScore + parsedThreshold
    }
}
