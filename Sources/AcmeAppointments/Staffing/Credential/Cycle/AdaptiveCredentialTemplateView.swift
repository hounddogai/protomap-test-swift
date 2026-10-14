import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive credential template.
    final class AdaptiveCredentialTemplateView {
        var code: String
        var name: String
        var endsAt: String
        var archivedText: String
        var summaryText: String
        var bedText: String
        var statusLabel: String

        init(code: String, name: String, endsAt: String, archivedText: String, summaryText: String, bedText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.archivedText = archivedText
            self.summaryText = summaryText
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCredentialTemplateView(_ item: AdaptiveCredentialTemplate) -> AdaptiveCredentialTemplateView {
        return AdaptiveCredentialTemplateView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            endsAt: String(item.endsAt),
            archivedText: "\(item.archived)",
            summaryText: item.summary,
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCredentialTemplateViews(_ items: [AdaptiveCredentialTemplate]) -> [AdaptiveCredentialTemplateView] {
        var views: [AdaptiveCredentialTemplateView] = []
        for item in items {
            views.append(toAdaptiveCredentialTemplateView(item))
        }
        return views
    }

    static func sumAdaptiveCredentialTemplateView(_ view: AdaptiveCredentialTemplateView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
