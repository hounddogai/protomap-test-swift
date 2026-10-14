import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive risk score checkpoint.
    final class AdaptiveRiskScoreCheckpointView {
        var codeText: String
        var name: String
        var copay: String
        var graceDays: String
        var batchSizeText: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, name: String, copay: String, graceDays: String, batchSizeText: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.copay = copay
            self.graceDays = graceDays
            self.batchSizeText = batchSizeText
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRiskScoreCheckpointView(_ item: AdaptiveRiskScoreCheckpoint) -> AdaptiveRiskScoreCheckpointView {
        return AdaptiveRiskScoreCheckpointView(
            codeText: item.code,
            name: item.name,
            copay: String(format: "%.2f", item.copay),
            graceDays: String(item.graceDays),
            batchSizeText: String(item.batchSize),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRiskScoreCheckpointViews(_ items: [AdaptiveRiskScoreCheckpoint]) -> [AdaptiveRiskScoreCheckpointView] {
        var views: [AdaptiveRiskScoreCheckpointView] = []
        for item in items {
            views.append(toAdaptiveRiskScoreCheckpointView(item))
        }
        return views
    }

    static func sumAdaptiveRiskScoreCheckpointView(_ view: AdaptiveRiskScoreCheckpointView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedCopay + Double(parsedGraceDays) + Double(parsedBatchSize)
    }
}
