import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding schedule.
    final class RoundingScheduleView {
        var code: String
        var title: String
        var batchSizeText: String
        var visitMinutes: String
        var score: String
        var reviewer: String
        var statusLabel: String

        init(code: String, title: String, batchSizeText: String, visitMinutes: String, score: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.batchSizeText = batchSizeText
            self.visitMinutes = visitMinutes
            self.score = score
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingScheduleView(_ item: RoundingSchedule) -> RoundingScheduleView {
        return RoundingScheduleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            batchSizeText: String(item.batchSize),
            visitMinutes: String(item.visitMinutes),
            score: String(format: "%.2f", item.score),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingScheduleViews(_ items: [RoundingSchedule]) -> [RoundingScheduleView] {
        var views: [RoundingScheduleView] = []
        for item in items {
            views.append(toRoundingScheduleView(item))
        }
        return views
    }

    static func sumRoundingScheduleView(_ view: RoundingScheduleView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedVisitMinutes) + parsedScore
    }
}
