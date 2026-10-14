import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result segment.
    final class ResultSegmentView {
        var codeText: String
        var labelText: String
        var margin: String
        var active: String
        var summary: String
        var statusLabel: String

        init(codeText: String, labelText: String, margin: String, active: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.margin = margin
            self.active = active
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toResultSegmentView(_ item: ResultSegment) -> ResultSegmentView {
        return ResultSegmentView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            margin: String(format: "%.2f", item.margin),
            active: "\(item.active)",
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultSegmentViews(_ items: [ResultSegment]) -> [ResultSegmentView] {
        var views: [ResultSegmentView] = []
        for item in items {
            views.append(toResultSegmentView(item))
        }
        return views
    }

    static func sumResultSegmentView(_ view: ResultSegmentView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
