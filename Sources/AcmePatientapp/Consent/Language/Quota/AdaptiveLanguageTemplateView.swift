import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive language template.
    final class AdaptiveLanguageTemplateView {
        var code: String
        var titleText: String
        var notesText: String
        var dosageMgText: String
        var amount: String
        var windowDays: String
        var statusLabel: String

        init(code: String, titleText: String, notesText: String, dosageMgText: String, amount: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.notesText = notesText
            self.dosageMgText = dosageMgText
            self.amount = amount
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveLanguageTemplateView(_ item: AdaptiveLanguageTemplate) -> AdaptiveLanguageTemplateView {
        return AdaptiveLanguageTemplateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            notesText: item.notes,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            amount: String(format: "%.2f", item.amount),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveLanguageTemplateViews(_ items: [AdaptiveLanguageTemplate]) -> [AdaptiveLanguageTemplateView] {
        var views: [AdaptiveLanguageTemplateView] = []
        for item in items {
            views.append(toAdaptiveLanguageTemplateView(item))
        }
        return views
    }

    static func sumAdaptiveLanguageTemplateView(_ view: AdaptiveLanguageTemplateView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedDosageMg + parsedAmount + Double(parsedWindowDays)
    }
}
