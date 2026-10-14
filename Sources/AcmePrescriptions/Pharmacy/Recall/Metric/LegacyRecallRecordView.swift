import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy recall record.
    final class LegacyRecallRecordView {
        var code: String
        var title: String
        var channel: String
        var region: String
        var diagnosisCode: String
        var externalRefText: String
        var scoreText: String
        var statusLabel: String

        init(code: String, title: String, channel: String, region: String, diagnosisCode: String, externalRefText: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.channel = channel
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.externalRefText = externalRefText
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyRecallRecordView(_ item: LegacyRecallRecord) -> LegacyRecallRecordView {
        return LegacyRecallRecordView(
            code: item.code,
            title: item.title,
            channel: Kit.Text.truncate(item.channel, limit: 64),
            region: item.region,
            diagnosisCode: item.diagnosisCode,
            externalRefText: item.externalRef,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyRecallRecordViews(_ items: [LegacyRecallRecord]) -> [LegacyRecallRecordView] {
        var views: [LegacyRecallRecordView] = []
        for item in items {
            views.append(toLegacyRecallRecordView(item))
        }
        return views
    }

    static func sumLegacyRecallRecordView(_ view: LegacyRecallRecordView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
