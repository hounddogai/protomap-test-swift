import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation proposal.
    final class IsolationProposalView {
        var code: String
        var titleText: String
        var approved: String
        var quantityText: String
        var discountText: String
        var statusLabel: String

        init(code: String, titleText: String, approved: String, quantityText: String, discountText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.approved = approved
            self.quantityText = quantityText
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationProposalView(_ item: IsolationProposal) -> IsolationProposalView {
        return IsolationProposalView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            approved: "\(item.approved)",
            quantityText: String(item.quantity),
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationProposalViews(_ items: [IsolationProposal]) -> [IsolationProposalView] {
        var views: [IsolationProposalView] = []
        for item in items {
            views.append(toIsolationProposalView(item))
        }
        return views
    }

    static func sumIsolationProposalView(_ view: IsolationProposalView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedQuantity) + parsedDiscount
    }
}
