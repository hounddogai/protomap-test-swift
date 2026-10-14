import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted formulary profile.
    final class WeightedFormularyProfileView {
        var code: String
        var label: String
        var retries: String
        var clinicianID: String
        var score: String
        var encounterID: String
        var statusLabel: String

        init(code: String, label: String, retries: String, clinicianID: String, score: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.retries = retries
            self.clinicianID = clinicianID
            self.score = score
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedFormularyProfileView(_ item: WeightedFormularyProfile) -> WeightedFormularyProfileView {
        return WeightedFormularyProfileView(
            code: item.code,
            label: item.label,
            retries: String(item.retries),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            score: String(format: "%.2f", item.score),
            encounterID: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedFormularyProfileViews(_ items: [WeightedFormularyProfile]) -> [WeightedFormularyProfileView] {
        var views: [WeightedFormularyProfileView] = []
        for item in items {
            views.append(toWeightedFormularyProfileView(item))
        }
        return views
    }

    static func sumWeightedFormularyProfileView(_ view: WeightedFormularyProfileView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedRetries) + parsedScore
    }
}
