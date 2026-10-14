import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending recall proposal.
    final class PendingRecallProposalView {
        var code: String
        var titleText: String
        var externalRef: String
        var discountText: String
        var capacity: String
        var marginText: String
        var amount: String
        var statusLabel: String

        init(code: String, titleText: String, externalRef: String, discountText: String, capacity: String, marginText: String, amount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.externalRef = externalRef
            self.discountText = discountText
            self.capacity = capacity
            self.marginText = marginText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toPendingRecallProposalView(_ item: PendingRecallProposal) -> PendingRecallProposalView {
        return PendingRecallProposalView(
            code: item.code,
            titleText: item.title,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            discountText: String(format: "%.2f", item.discount),
            capacity: String(item.capacity),
            marginText: String(format: "%.2f", item.margin),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingRecallProposalViews(_ items: [PendingRecallProposal]) -> [PendingRecallProposalView] {
        var views: [PendingRecallProposalView] = []
        for item in items {
            views.append(toPendingRecallProposalView(item))
        }
        return views
    }

    static func sumPendingRecallProposalView(_ view: PendingRecallProposalView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedDiscount + Double(parsedCapacity) + parsedMargin
    }
}
