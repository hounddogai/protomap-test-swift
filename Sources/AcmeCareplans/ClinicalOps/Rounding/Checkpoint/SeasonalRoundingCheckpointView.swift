import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a seasonal rounding checkpoint.
    final class SeasonalRoundingCheckpointView {
        var code: String
        var titleText: String
        var amount: String
        var channel: String
        var refills: String
        var batchSizeText: String
        var diagnosisCode: String
        var ward: String
        var maximum: String
        var archivedText: String
        var statusLabel: String

        init(code: String, titleText: String, amount: String, channel: String, refills: String, batchSizeText: String, diagnosisCode: String, ward: String, maximum: String, archivedText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.amount = amount
            self.channel = channel
            self.refills = refills
            self.batchSizeText = batchSizeText
            self.diagnosisCode = diagnosisCode
            self.ward = ward
            self.maximum = maximum
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalRoundingCheckpointView(_ item: SeasonalRoundingCheckpoint) -> SeasonalRoundingCheckpointView {
        return SeasonalRoundingCheckpointView(
            code: item.code,
            titleText: item.title,
            amount: String(format: "%.2f", item.amount),
            channel: item.channel,
            refills: String(item.refills),
            batchSizeText: String(item.batchSize),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            ward: item.ward,
            maximum: String(format: "%.2f", item.maximum),
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalRoundingCheckpointViews(_ items: [SeasonalRoundingCheckpoint]) -> [SeasonalRoundingCheckpointView] {
        var views: [SeasonalRoundingCheckpointView] = []
        for item in items {
            views.append(toSeasonalRoundingCheckpointView(item))
        }
        return views
    }

    static func sumSeasonalRoundingCheckpointView(_ view: SeasonalRoundingCheckpointView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedAmount + Double(parsedRefills) + Double(parsedBatchSize)
    }
}
