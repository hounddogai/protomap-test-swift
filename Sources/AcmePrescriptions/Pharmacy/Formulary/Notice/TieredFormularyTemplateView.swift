import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a tiered formulary template.
    final class TieredFormularyTemplateView {
        var code: String
        var label: String
        var createdAtText: String
        var attemptsText: String
        var limitText: String
        var payer: String
        var statusLabel: String

        init(code: String, label: String, createdAtText: String, attemptsText: String, limitText: String, payer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAtText = createdAtText
            self.attemptsText = attemptsText
            self.limitText = limitText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toTieredFormularyTemplateView(_ item: TieredFormularyTemplate) -> TieredFormularyTemplateView {
        return TieredFormularyTemplateView(
            code: item.code,
            label: item.label,
            createdAtText: String(item.createdAt),
            attemptsText: String(item.attempts),
            limitText: String(item.limit),
            payer: Kit.Text.truncate(item.payer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredFormularyTemplateViews(_ items: [TieredFormularyTemplate]) -> [TieredFormularyTemplateView] {
        var views: [TieredFormularyTemplateView] = []
        for item in items {
            views.append(toTieredFormularyTemplateView(item))
        }
        return views
    }

    static func sumTieredFormularyTemplateView(_ view: TieredFormularyTemplateView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedAttempts) + Double(parsedLimit)
    }
}
