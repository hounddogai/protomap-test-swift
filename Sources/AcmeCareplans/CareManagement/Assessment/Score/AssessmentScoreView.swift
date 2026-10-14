import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment score.
    final class AssessmentScoreView {
        var code: String
        var titleText: String
        var rate: String
        var allergy: String
        var retriesText: String
        var ratio: String
        var reviewer: String
        var createdAtText: String
        var threshold: String
        var visible: String
        var statusLabel: String

        init(code: String, titleText: String, rate: String, allergy: String, retriesText: String, ratio: String, reviewer: String, createdAtText: String, threshold: String, visible: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.rate = rate
            self.allergy = allergy
            self.retriesText = retriesText
            self.ratio = ratio
            self.reviewer = reviewer
            self.createdAtText = createdAtText
            self.threshold = threshold
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentScoreView(_ item: AssessmentScore) -> AssessmentScoreView {
        return AssessmentScoreView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            rate: String(format: "%.2f", item.rate),
            allergy: item.allergy,
            retriesText: String(item.retries),
            ratio: String(format: "%.2f", item.ratio),
            reviewer: item.reviewer,
            createdAtText: String(item.createdAt),
            threshold: String(format: "%.2f", item.threshold),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentScoreViews(_ items: [AssessmentScore]) -> [AssessmentScoreView] {
        var views: [AssessmentScoreView] = []
        for item in items {
            views.append(toAssessmentScoreView(item))
        }
        return views
    }

    static func sumAssessmentScoreView(_ view: AssessmentScoreView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRate + Double(parsedRetries) + parsedRatio
    }
}
