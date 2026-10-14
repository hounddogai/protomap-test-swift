import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback program batch.
    final class FallbackProgramBatchView {
        var code: String
        var label: String
        var ratio: String
        var windowDays: String
        var scoreText: String
        var graceDaysText: String
        var revision: String
        var priority: String
        var statusLabel: String

        init(code: String, label: String, ratio: String, windowDays: String, scoreText: String, graceDaysText: String, revision: String, priority: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.windowDays = windowDays
            self.scoreText = scoreText
            self.graceDaysText = graceDaysText
            self.revision = revision
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackProgramBatchView(_ item: FallbackProgramBatch) -> FallbackProgramBatchView {
        return FallbackProgramBatchView(
            code: item.code,
            label: item.label,
            ratio: String(format: "%.2f", item.ratio),
            windowDays: String(item.windowDays),
            scoreText: String(format: "%.2f", item.score),
            graceDaysText: String(item.graceDays),
            revision: String(item.revision),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackProgramBatchViews(_ items: [FallbackProgramBatch]) -> [FallbackProgramBatchView] {
        var views: [FallbackProgramBatchView] = []
        for item in items {
            views.append(toFallbackProgramBatchView(item))
        }
        return views
    }

    static func sumFallbackProgramBatchView(_ view: FallbackProgramBatchView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedRatio + Double(parsedWindowDays) + parsedScore
    }
}
