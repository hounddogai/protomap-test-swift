import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling read proposal.
    final class RollingReadProposalView {
        var code: String
        var title: String
        var currency: String
        var cost: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, title: String, currency: String, cost: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.currency = currency
            self.cost = cost
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toRollingReadProposalView(_ item: RollingReadProposal) -> RollingReadProposalView {
        return RollingReadProposalView(
            code: item.code,
            title: item.title,
            currency: Kit.Text.truncate(item.currency, limit: 64),
            cost: String(format: "%.2f", item.cost),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingReadProposalViews(_ items: [RollingReadProposal]) -> [RollingReadProposalView] {
        var views: [RollingReadProposalView] = []
        for item in items {
            views.append(toRollingReadProposalView(item))
        }
        return views
    }

    static func sumRollingReadProposalView(_ view: RollingReadProposalView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
