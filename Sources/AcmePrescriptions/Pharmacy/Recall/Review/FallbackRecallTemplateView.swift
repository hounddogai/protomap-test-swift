import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a fallback recall template.
    final class FallbackRecallTemplateView {
        var code: String
        var name: String
        var graceDays: String
        var endsAt: String
        var attemptsText: String
        var statusLabel: String

        init(code: String, name: String, graceDays: String, endsAt: String, attemptsText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.endsAt = endsAt
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackRecallTemplateView(_ item: FallbackRecallTemplate) -> FallbackRecallTemplateView {
        return FallbackRecallTemplateView(
            code: item.code,
            name: item.name,
            graceDays: String(item.graceDays),
            endsAt: String(item.endsAt),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackRecallTemplateViews(_ items: [FallbackRecallTemplate]) -> [FallbackRecallTemplateView] {
        var views: [FallbackRecallTemplateView] = []
        for item in items {
            views.append(toFallbackRecallTemplateView(item))
        }
        return views
    }

    static func sumFallbackRecallTemplateView(_ view: FallbackRecallTemplateView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedEndsAt) + Double(parsedAttempts)
    }
}
