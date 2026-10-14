import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census summary.
    final class CensusSummaryView {
        var code: String
        var label: String
        var allergy: String
        var country: String
        var priority: String
        var titleText: String
        var specialtyText: String
        var scoreText: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, label: String, allergy: String, country: String, priority: String, titleText: String, specialtyText: String, scoreText: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.country = country
            self.priority = priority
            self.titleText = titleText
            self.specialtyText = specialtyText
            self.scoreText = scoreText
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusSummaryView(_ item: CensusSummary) -> CensusSummaryView {
        return CensusSummaryView(
            code: item.code,
            label: item.label,
            allergy: item.allergy,
            country: Kit.Text.truncate(item.country, limit: 40),
            priority: String(item.priority),
            titleText: Kit.Text.truncate(item.title, limit: 64),
            specialtyText: item.specialty,
            scoreText: String(format: "%.2f", item.score),
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusSummaryViews(_ items: [CensusSummary]) -> [CensusSummaryView] {
        var views: [CensusSummaryView] = []
        for item in items {
            views.append(toCensusSummaryView(item))
        }
        return views
    }

    static func sumCensusSummaryView(_ view: CensusSummaryView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedPriority) + parsedScore + Double(parsedBatchSize)
    }
}
