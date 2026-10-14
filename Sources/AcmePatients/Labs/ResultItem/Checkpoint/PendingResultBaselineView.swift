import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending result baseline.
    final class PendingResultBaselineView {
        var code: String
        var label: String
        var nameText: String
        var diagnosisCode: String
        var summaryText: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, nameText: String, diagnosisCode: String, summaryText: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.nameText = nameText
            self.diagnosisCode = diagnosisCode
            self.summaryText = summaryText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toPendingResultBaselineView(_ item: PendingResultBaseline) -> PendingResultBaselineView {
        return PendingResultBaselineView(
            code: item.code,
            label: item.label,
            nameText: item.name,
            diagnosisCode: item.diagnosisCode,
            summaryText: item.summary,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingResultBaselineViews(_ items: [PendingResultBaseline]) -> [PendingResultBaselineView] {
        var views: [PendingResultBaselineView] = []
        for item in items {
            views.append(toPendingResultBaselineView(item))
        }
        return views
    }

    static func sumPendingResultBaselineView(_ view: PendingResultBaselineView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
