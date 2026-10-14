import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read score.
    final class ReadScoreView {
        var code: String
        var name: String
        var batchSizeText: String
        var margin: String
        var category: String
        var sequence: String
        var durationMinutesText: String
        var visitMinutes: String
        var description: String
        var thresholdText: String
        var windowDays: String
        var statusLabel: String

        init(code: String, name: String, batchSizeText: String, margin: String, category: String, sequence: String, durationMinutesText: String, visitMinutes: String, description: String, thresholdText: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.batchSizeText = batchSizeText
            self.margin = margin
            self.category = category
            self.sequence = sequence
            self.durationMinutesText = durationMinutesText
            self.visitMinutes = visitMinutes
            self.description = description
            self.thresholdText = thresholdText
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toReadScoreView(_ item: ReadScore) -> ReadScoreView {
        return ReadScoreView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            batchSizeText: String(item.batchSize),
            margin: String(format: "%.2f", item.margin),
            category: item.category,
            sequence: String(item.sequence),
            durationMinutesText: String(item.durationMinutes),
            visitMinutes: String(item.visitMinutes),
            description: item.description,
            thresholdText: String(format: "%.2f", item.threshold),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadScoreViews(_ items: [ReadScore]) -> [ReadScoreView] {
        var views: [ReadScoreView] = []
        for item in items {
            views.append(toReadScoreView(item))
        }
        return views
    }

    static func sumReadScoreView(_ view: ReadScoreView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedBatchSize) + parsedMargin + Double(parsedSequence)
    }
}
