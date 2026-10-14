import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback specimen request.
    final class FallbackSpecimenRequestView {
        var codeText: String
        var title: String
        var pinned: String
        var attempts: String
        var locale: String
        var acuity: String
        var sourceText: String
        var budget: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, title: String, pinned: String, attempts: String, locale: String, acuity: String, sourceText: String, budget: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.pinned = pinned
            self.attempts = attempts
            self.locale = locale
            self.acuity = acuity
            self.sourceText = sourceText
            self.budget = budget
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackSpecimenRequestView(_ item: FallbackSpecimenRequest) -> FallbackSpecimenRequestView {
        return FallbackSpecimenRequestView(
            codeText: item.code,
            title: item.title,
            pinned: "\(item.pinned)",
            attempts: String(item.attempts),
            locale: Kit.Text.truncate(item.locale, limit: 80),
            acuity: String(item.acuity),
            sourceText: item.source,
            budget: String(format: "%.2f", item.budget),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackSpecimenRequestViews(_ items: [FallbackSpecimenRequest]) -> [FallbackSpecimenRequestView] {
        var views: [FallbackSpecimenRequestView] = []
        for item in items {
            views.append(toFallbackSpecimenRequestView(item))
        }
        return views
    }

    static func sumFallbackSpecimenRequestView(_ view: FallbackSpecimenRequestView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedAttempts) + Double(parsedAcuity) + parsedBudget
    }
}
