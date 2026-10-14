import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal assessment snapshot.
    final class SeasonalAssessmentSnapshotView {
        var codeText: String
        var titleText: String
        var graceDays: String
        var rateText: String
        var batchSize: String
        var capacity: String
        var category: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, titleText: String, graceDays: String, rateText: String, batchSize: String, capacity: String, category: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.graceDays = graceDays
            self.rateText = rateText
            self.batchSize = batchSize
            self.capacity = capacity
            self.category = category
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalAssessmentSnapshotView(_ item: SeasonalAssessmentSnapshot) -> SeasonalAssessmentSnapshotView {
        return SeasonalAssessmentSnapshotView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            graceDays: String(item.graceDays),
            rateText: String(format: "%.2f", item.rate),
            batchSize: String(item.batchSize),
            capacity: String(item.capacity),
            category: Kit.Text.truncate(item.category, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalAssessmentSnapshotViews(_ items: [SeasonalAssessmentSnapshot]) -> [SeasonalAssessmentSnapshotView] {
        var views: [SeasonalAssessmentSnapshotView] = []
        for item in items {
            views.append(toSeasonalAssessmentSnapshotView(item))
        }
        return views
    }

    static func sumSeasonalAssessmentSnapshotView(_ view: SeasonalAssessmentSnapshotView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedGraceDays) + parsedRate + Double(parsedBatchSize)
    }
}
