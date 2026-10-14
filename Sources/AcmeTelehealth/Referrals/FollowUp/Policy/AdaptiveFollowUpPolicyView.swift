import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a adaptive follow up policy.
    final class AdaptiveFollowUpPolicyView {
        var code: String
        var label: String
        var margin: String
        var visibleText: String
        var copay: String
        var statusLabel: String

        init(code: String, label: String, margin: String, visibleText: String, copay: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.margin = margin
            self.visibleText = visibleText
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveFollowUpPolicyView(_ item: AdaptiveFollowUpPolicy) -> AdaptiveFollowUpPolicyView {
        return AdaptiveFollowUpPolicyView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            margin: String(format: "%.2f", item.margin),
            visibleText: "\(item.visible)",
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveFollowUpPolicyViews(_ items: [AdaptiveFollowUpPolicy]) -> [AdaptiveFollowUpPolicyView] {
        var views: [AdaptiveFollowUpPolicyView] = []
        for item in items {
            views.append(toAdaptiveFollowUpPolicyView(item))
        }
        return views
    }

    static func sumAdaptiveFollowUpPolicyView(_ view: AdaptiveFollowUpPolicyView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedMargin + parsedCopay
    }
}
