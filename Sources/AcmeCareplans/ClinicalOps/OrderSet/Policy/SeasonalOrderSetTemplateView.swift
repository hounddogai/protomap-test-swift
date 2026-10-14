import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a seasonal order set template.
    final class SeasonalOrderSetTemplateView {
        var code: String
        var labelText: String
        var visibleText: String
        var rate: String
        var nameText: String
        var patientRef: String
        var statusLabel: String

        init(code: String, labelText: String, visibleText: String, rate: String, nameText: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.visibleText = visibleText
            self.rate = rate
            self.nameText = nameText
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalOrderSetTemplateView(_ item: SeasonalOrderSetTemplate) -> SeasonalOrderSetTemplateView {
        return SeasonalOrderSetTemplateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            visibleText: "\(item.visible)",
            rate: String(format: "%.2f", item.rate),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalOrderSetTemplateViews(_ items: [SeasonalOrderSetTemplate]) -> [SeasonalOrderSetTemplateView] {
        var views: [SeasonalOrderSetTemplateView] = []
        for item in items {
            views.append(toSeasonalOrderSetTemplateView(item))
        }
        return views
    }

    static func sumSeasonalOrderSetTemplateView(_ view: SeasonalOrderSetTemplateView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
