import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a fallback language template.
    final class FallbackLanguageTemplateView {
        var code: String
        var titleText: String
        var maximum: String
        var archived: String
        var reviewer: String
        var activeText: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, titleText: String, maximum: String, archived: String, reviewer: String, activeText: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.maximum = maximum
            self.archived = archived
            self.reviewer = reviewer
            self.activeText = activeText
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackLanguageTemplateView(_ item: FallbackLanguageTemplate) -> FallbackLanguageTemplateView {
        return FallbackLanguageTemplateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            maximum: String(format: "%.2f", item.maximum),
            archived: "\(item.archived)",
            reviewer: Kit.Text.truncate(item.reviewer, limit: 40),
            activeText: "\(item.active)",
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackLanguageTemplateViews(_ items: [FallbackLanguageTemplate]) -> [FallbackLanguageTemplateView] {
        var views: [FallbackLanguageTemplateView] = []
        for item in items {
            views.append(toFallbackLanguageTemplateView(item))
        }
        return views
    }

    static func sumFallbackLanguageTemplateView(_ view: FallbackLanguageTemplateView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedMaximum + Double(parsedUpdatedAt)
    }
}
