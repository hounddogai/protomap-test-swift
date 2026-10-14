import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation template.
    final class IsolationTemplateView {
        var code: String
        var labelText: String
        var name: String
        var threshold: String
        var scoreText: String
        var sourceText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, labelText: String, name: String, threshold: String, scoreText: String, sourceText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.name = name
            self.threshold = threshold
            self.scoreText = scoreText
            self.sourceText = sourceText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationTemplateView(_ item: IsolationTemplate) -> IsolationTemplateView {
        return IsolationTemplateView(
            code: item.code,
            labelText: item.label,
            name: item.name,
            threshold: String(format: "%.2f", item.threshold),
            scoreText: String(format: "%.2f", item.score),
            sourceText: item.source,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationTemplateViews(_ items: [IsolationTemplate]) -> [IsolationTemplateView] {
        var views: [IsolationTemplateView] = []
        for item in items {
            views.append(toIsolationTemplateView(item))
        }
        return views
    }

    static func sumIsolationTemplateView(_ view: IsolationTemplateView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedThreshold + parsedScore
    }
}
