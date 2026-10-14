import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted credential rollup.
    final class WeightedCredentialRollupView {
        var code: String
        var label: String
        var dosageMgText: String
        var score: String
        var durationMinutes: String
        var ratio: String
        var specialty: String
        var thresholdText: String
        var channelText: String
        var cost: String
        var statusLabel: String

        init(code: String, label: String, dosageMgText: String, score: String, durationMinutes: String, ratio: String, specialty: String, thresholdText: String, channelText: String, cost: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.dosageMgText = dosageMgText
            self.score = score
            self.durationMinutes = durationMinutes
            self.ratio = ratio
            self.specialty = specialty
            self.thresholdText = thresholdText
            self.channelText = channelText
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCredentialRollupView(_ item: WeightedCredentialRollup) -> WeightedCredentialRollupView {
        return WeightedCredentialRollupView(
            code: item.code,
            label: item.label,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            score: String(format: "%.2f", item.score),
            durationMinutes: String(item.durationMinutes),
            ratio: String(format: "%.2f", item.ratio),
            specialty: item.specialty,
            thresholdText: String(format: "%.2f", item.threshold),
            channelText: Kit.Text.truncate(item.channel, limit: 80),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCredentialRollupViews(_ items: [WeightedCredentialRollup]) -> [WeightedCredentialRollupView] {
        var views: [WeightedCredentialRollupView] = []
        for item in items {
            views.append(toWeightedCredentialRollupView(item))
        }
        return views
    }

    static func sumWeightedCredentialRollupView(_ view: WeightedCredentialRollupView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedDosageMg + parsedScore + Double(parsedDurationMinutes)
    }
}
