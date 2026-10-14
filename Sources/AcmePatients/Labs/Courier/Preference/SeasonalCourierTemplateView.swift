import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal courier template.
    final class SeasonalCourierTemplateView {
        var codeText: String
        var name: String
        var unitText: String
        var approved: String
        var label: String
        var payer: String
        var cost: String
        var rateText: String
        var statusLabel: String

        init(codeText: String, name: String, unitText: String, approved: String, label: String, payer: String, cost: String, rateText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.unitText = unitText
            self.approved = approved
            self.label = label
            self.payer = payer
            self.cost = cost
            self.rateText = rateText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCourierTemplateView(_ item: SeasonalCourierTemplate) -> SeasonalCourierTemplateView {
        return SeasonalCourierTemplateView(
            codeText: item.code,
            name: item.name,
            unitText: item.unit,
            approved: "\(item.approved)",
            label: item.label,
            payer: item.payer,
            cost: String(format: "%.2f", item.cost),
            rateText: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCourierTemplateViews(_ items: [SeasonalCourierTemplate]) -> [SeasonalCourierTemplateView] {
        var views: [SeasonalCourierTemplateView] = []
        for item in items {
            views.append(toSeasonalCourierTemplateView(item))
        }
        return views
    }

    static func sumSeasonalCourierTemplateView(_ view: SeasonalCourierTemplateView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedCost + parsedRate
    }
}
