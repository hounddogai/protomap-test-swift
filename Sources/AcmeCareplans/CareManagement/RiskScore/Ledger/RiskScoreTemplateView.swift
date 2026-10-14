import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score template.
    final class RiskScoreTemplateView {
        var code: String
        var name: String
        var title: String
        var patientRefText: String
        var visibleText: String
        var ratio: String
        var priority: String
        var source: String
        var statusLabel: String

        init(code: String, name: String, title: String, patientRefText: String, visibleText: String, ratio: String, priority: String, source: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.title = title
            self.patientRefText = patientRefText
            self.visibleText = visibleText
            self.ratio = ratio
            self.priority = priority
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreTemplateView(_ item: RiskScoreTemplate) -> RiskScoreTemplateView {
        return RiskScoreTemplateView(
            code: item.code,
            name: item.name,
            title: item.title,
            patientRefText: item.patientRef,
            visibleText: "\(item.visible)",
            ratio: String(format: "%.2f", item.ratio),
            priority: String(item.priority),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreTemplateViews(_ items: [RiskScoreTemplate]) -> [RiskScoreTemplateView] {
        var views: [RiskScoreTemplateView] = []
        for item in items {
            views.append(toRiskScoreTemplateView(item))
        }
        return views
    }

    static func sumRiskScoreTemplateView(_ view: RiskScoreTemplateView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedRatio + Double(parsedPriority)
    }
}
