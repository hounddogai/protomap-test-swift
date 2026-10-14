import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language override.
    final class LanguageOverrideView {
        var code: String
        var nameText: String
        var approvedText: String
        var rate: String
        var summary: String
        var unit: String
        var activeText: String
        var endsAtText: String
        var margin: String
        var createdAt: String
        var statusLabel: String

        init(code: String, nameText: String, approvedText: String, rate: String, summary: String, unit: String, activeText: String, endsAtText: String, margin: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.approvedText = approvedText
            self.rate = rate
            self.summary = summary
            self.unit = unit
            self.activeText = activeText
            self.endsAtText = endsAtText
            self.margin = margin
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageOverrideView(_ item: LanguageOverride) -> LanguageOverrideView {
        return LanguageOverrideView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            approvedText: "\(item.approved)",
            rate: String(format: "%.2f", item.rate),
            summary: item.summary,
            unit: Kit.Text.truncate(item.unit, limit: 40),
            activeText: "\(item.active)",
            endsAtText: String(item.endsAt),
            margin: String(format: "%.2f", item.margin),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageOverrideViews(_ items: [LanguageOverride]) -> [LanguageOverrideView] {
        var views: [LanguageOverrideView] = []
        for item in items {
            views.append(toLanguageOverrideView(item))
        }
        return views
    }

    static func sumLanguageOverrideView(_ view: LanguageOverrideView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedRate + Double(parsedEndsAt) + parsedMargin
    }
}
