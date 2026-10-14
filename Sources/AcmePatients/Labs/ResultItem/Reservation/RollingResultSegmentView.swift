import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling result segment.
    final class RollingResultSegmentView {
        var codeText: String
        var label: String
        var batchSize: String
        var score: String
        var locale: String
        var summary: String
        var statusLabel: String

        init(codeText: String, label: String, batchSize: String, score: String, locale: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.batchSize = batchSize
            self.score = score
            self.locale = locale
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toRollingResultSegmentView(_ item: RollingResultSegment) -> RollingResultSegmentView {
        return RollingResultSegmentView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            batchSize: String(item.batchSize),
            score: String(format: "%.2f", item.score),
            locale: item.locale,
            summary: Kit.Text.truncate(item.summary, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingResultSegmentViews(_ items: [RollingResultSegment]) -> [RollingResultSegmentView] {
        var views: [RollingResultSegmentView] = []
        for item in items {
            views.append(toRollingResultSegmentView(item))
        }
        return views
    }

    static func sumRollingResultSegmentView(_ view: RollingResultSegmentView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedBatchSize) + parsedScore
    }
}
