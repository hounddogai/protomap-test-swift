import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a legacy study estimate.
    final class LegacyStudyEstimateView {
        var code: String
        var title: String
        var diagnosisCode: String
        var visitMinutesText: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, diagnosisCode: String, visitMinutesText: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.visitMinutesText = visitMinutesText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyStudyEstimateView(_ item: LegacyStudyEstimate) -> LegacyStudyEstimateView {
        return LegacyStudyEstimateView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            diagnosisCode: item.diagnosisCode,
            visitMinutesText: String(item.visitMinutes),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyStudyEstimateViews(_ items: [LegacyStudyEstimate]) -> [LegacyStudyEstimateView] {
        var views: [LegacyStudyEstimateView] = []
        for item in items {
            views.append(toLegacyStudyEstimateView(item))
        }
        return views
    }

    static func sumLegacyStudyEstimateView(_ view: LegacyStudyEstimateView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedVisitMinutes) + parsedScore
    }
}
