import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal risk score policy.
    final class SeasonalRiskScorePolicyView {
        var codeText: String
        var nameText: String
        var copay: String
        var ceiling: String
        var score: String
        var country: String
        var procedureCode: String
        var revision: String
        var statusLabel: String

        init(codeText: String, nameText: String, copay: String, ceiling: String, score: String, country: String, procedureCode: String, revision: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.copay = copay
            self.ceiling = ceiling
            self.score = score
            self.country = country
            self.procedureCode = procedureCode
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalRiskScorePolicyView(_ item: SeasonalRiskScorePolicy) -> SeasonalRiskScorePolicyView {
        return SeasonalRiskScorePolicyView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            copay: String(format: "%.2f", item.copay),
            ceiling: String(format: "%.2f", item.ceiling),
            score: String(format: "%.2f", item.score),
            country: item.country,
            procedureCode: item.procedureCode,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalRiskScorePolicyViews(_ items: [SeasonalRiskScorePolicy]) -> [SeasonalRiskScorePolicyView] {
        var views: [SeasonalRiskScorePolicyView] = []
        for item in items {
            views.append(toSeasonalRiskScorePolicyView(item))
        }
        return views
    }

    static func sumSeasonalRiskScorePolicyView(_ view: SeasonalRiskScorePolicyView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedCopay + parsedCeiling + parsedScore
    }
}
