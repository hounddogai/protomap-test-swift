import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual float pool summary.
    final class ManualFloatPoolSummaryView {
        var codeText: String
        var name: String
        var maximum: String
        var label: String
        var score: String
        var statusLabel: String

        init(codeText: String, name: String, maximum: String, label: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.maximum = maximum
            self.label = label
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toManualFloatPoolSummaryView(_ item: ManualFloatPoolSummary) -> ManualFloatPoolSummaryView {
        return ManualFloatPoolSummaryView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            maximum: String(format: "%.2f", item.maximum),
            label: item.label,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualFloatPoolSummaryViews(_ items: [ManualFloatPoolSummary]) -> [ManualFloatPoolSummaryView] {
        var views: [ManualFloatPoolSummaryView] = []
        for item in items {
            views.append(toManualFloatPoolSummaryView(item))
        }
        return views
    }

    static func sumManualFloatPoolSummaryView(_ view: ManualFloatPoolSummaryView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedMaximum + parsedScore
    }
}
