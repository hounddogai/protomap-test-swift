import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score record.
    final class RiskScoreRecordView {
        var codeText: String
        var name: String
        var channel: String
        var dosageMg: String
        var encounterID: String
        var score: String
        var region: String
        var statusLabel: String

        init(codeText: String, name: String, channel: String, dosageMg: String, encounterID: String, score: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.channel = channel
            self.dosageMg = dosageMg
            self.encounterID = encounterID
            self.score = score
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreRecordView(_ item: RiskScoreRecord) -> RiskScoreRecordView {
        return RiskScoreRecordView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            channel: item.channel,
            dosageMg: String(format: "%.2f", item.dosageMg),
            encounterID: item.encounterID,
            score: String(format: "%.2f", item.score),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreRecordViews(_ items: [RiskScoreRecord]) -> [RiskScoreRecordView] {
        var views: [RiskScoreRecordView] = []
        for item in items {
            views.append(toRiskScoreRecordView(item))
        }
        return views
    }

    static func sumRiskScoreRecordView(_ view: RiskScoreRecordView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedDosageMg + parsedScore
    }
}
