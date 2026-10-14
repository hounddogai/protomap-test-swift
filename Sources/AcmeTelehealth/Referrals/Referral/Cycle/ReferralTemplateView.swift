import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral template.
    final class ReferralTemplateView {
        var code: String
        var title: String
        var labelText: String
        var revision: String
        var limit: String
        var statusLabel: String

        init(code: String, title: String, labelText: String, revision: String, limit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.labelText = labelText
            self.revision = revision
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toReferralTemplateView(_ item: ReferralTemplate) -> ReferralTemplateView {
        return ReferralTemplateView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 120),
            labelText: Kit.Text.truncate(item.label, limit: 120),
            revision: String(item.revision),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralTemplateViews(_ items: [ReferralTemplate]) -> [ReferralTemplateView] {
        var views: [ReferralTemplateView] = []
        for item in items {
            views.append(toReferralTemplateView(item))
        }
        return views
    }

    static func sumReferralTemplateView(_ view: ReferralTemplateView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedRevision) + Double(parsedLimit)
    }
}
