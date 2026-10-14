import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim assignment.
    final class ClaimAssignmentView {
        var codeText: String
        var titleText: String
        var phone: String
        var segment: String
        var contactEmail: String
        var amount: String
        var statusLabel: String

        init(codeText: String, titleText: String, phone: String, segment: String, contactEmail: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.phone = phone
            self.segment = segment
            self.contactEmail = contactEmail
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toClaimAssignmentView(_ item: ClaimAssignment) -> ClaimAssignmentView {
        return ClaimAssignmentView(
            codeText: item.code,
            titleText: item.title,
            phone: item.phone,
            segment: item.segment,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimAssignmentViews(_ items: [ClaimAssignment]) -> [ClaimAssignmentView] {
        var views: [ClaimAssignmentView] = []
        for item in items {
            views.append(toClaimAssignmentView(item))
        }
        return views
    }

    static func sumClaimAssignmentView(_ view: ClaimAssignmentView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
