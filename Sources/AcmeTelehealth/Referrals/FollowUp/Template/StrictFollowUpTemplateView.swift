import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict follow up template.
    final class StrictFollowUpTemplateView {
        var codeText: String
        var label: String
        var acuityText: String
        var endsAt: String
        var createdAtText: String
        var discount: String
        var statusLabel: String

        init(codeText: String, label: String, acuityText: String, endsAt: String, createdAtText: String, discount: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.acuityText = acuityText
            self.endsAt = endsAt
            self.createdAtText = createdAtText
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toStrictFollowUpTemplateView(_ item: StrictFollowUpTemplate) -> StrictFollowUpTemplateView {
        return StrictFollowUpTemplateView(
            codeText: item.code,
            label: item.label,
            acuityText: String(item.acuity),
            endsAt: String(item.endsAt),
            createdAtText: String(item.createdAt),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictFollowUpTemplateViews(_ items: [StrictFollowUpTemplate]) -> [StrictFollowUpTemplateView] {
        var views: [StrictFollowUpTemplateView] = []
        for item in items {
            views.append(toStrictFollowUpTemplateView(item))
        }
        return views
    }

    static func sumStrictFollowUpTemplateView(_ view: StrictFollowUpTemplateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedEndsAt) + Double(parsedCreatedAt)
    }
}
