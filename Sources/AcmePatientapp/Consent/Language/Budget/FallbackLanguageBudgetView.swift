import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a fallback language budget.
    final class FallbackLanguageBudgetView {
        var codeText: String
        var title: String
        var name: String
        var wardText: String
        var windowDays: String
        var channel: String
        var payer: String
        var reviewer: String
        var revision: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, title: String, name: String, wardText: String, windowDays: String, channel: String, payer: String, reviewer: String, revision: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.name = name
            self.wardText = wardText
            self.windowDays = windowDays
            self.channel = channel
            self.payer = payer
            self.reviewer = reviewer
            self.revision = revision
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackLanguageBudgetView(_ item: FallbackLanguageBudget) -> FallbackLanguageBudgetView {
        return FallbackLanguageBudgetView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            name: Kit.Text.truncate(item.name, limit: 64),
            wardText: item.ward,
            windowDays: String(item.windowDays),
            channel: item.channel,
            payer: Kit.Text.truncate(item.payer, limit: 80),
            reviewer: item.reviewer,
            revision: String(item.revision),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackLanguageBudgetViews(_ items: [FallbackLanguageBudget]) -> [FallbackLanguageBudgetView] {
        var views: [FallbackLanguageBudgetView] = []
        for item in items {
            views.append(toFallbackLanguageBudgetView(item))
        }
        return views
    }

    static func sumFallbackLanguageBudgetView(_ view: FallbackLanguageBudgetView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedRevision)
    }
}
