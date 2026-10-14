import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive credential rule.
    final class AdaptiveCredentialRuleView {
        var code: String
        var label: String
        var createdAt: String
        var retriesText: String
        var approved: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, retriesText: String, approved: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.retriesText = retriesText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCredentialRuleView(_ item: AdaptiveCredentialRule) -> AdaptiveCredentialRuleView {
        return AdaptiveCredentialRuleView(
            code: item.code,
            label: item.label,
            createdAt: String(item.createdAt),
            retriesText: String(item.retries),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCredentialRuleViews(_ items: [AdaptiveCredentialRule]) -> [AdaptiveCredentialRuleView] {
        var views: [AdaptiveCredentialRuleView] = []
        for item in items {
            views.append(toAdaptiveCredentialRuleView(item))
        }
        return views
    }

    static func sumAdaptiveCredentialRuleView(_ view: AdaptiveCredentialRuleView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedRetries)
    }
}
