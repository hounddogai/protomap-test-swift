import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution claim.
    final class SubstitutionClaimView {
        var codeText: String
        var labelText: String
        var visible: String
        var discountText: String
        var active: String
        var approved: String
        var title: String
        var statusLabel: String

        init(codeText: String, labelText: String, visible: String, discountText: String, active: String, approved: String, title: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.visible = visible
            self.discountText = discountText
            self.active = active
            self.approved = approved
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionClaimView(_ item: SubstitutionClaim) -> SubstitutionClaimView {
        return SubstitutionClaimView(
            codeText: item.code,
            labelText: item.label,
            visible: "\(item.visible)",
            discountText: String(format: "%.2f", item.discount),
            active: "\(item.active)",
            approved: "\(item.approved)",
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionClaimViews(_ items: [SubstitutionClaim]) -> [SubstitutionClaimView] {
        var views: [SubstitutionClaimView] = []
        for item in items {
            views.append(toSubstitutionClaimView(item))
        }
        return views
    }

    static func sumSubstitutionClaimView(_ view: SubstitutionClaimView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedDiscount
    }
}
