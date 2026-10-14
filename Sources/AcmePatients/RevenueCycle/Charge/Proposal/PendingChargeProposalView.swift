import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending charge proposal.
    final class PendingChargeProposalView {
        var code: String
        var titleText: String
        var maximumText: String
        var budget: String
        var ratio: String
        var acuity: String
        var channel: String
        var amountText: String
        var approved: String
        var graceDays: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, titleText: String, maximumText: String, budget: String, ratio: String, acuity: String, channel: String, amountText: String, approved: String, graceDays: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.maximumText = maximumText
            self.budget = budget
            self.ratio = ratio
            self.acuity = acuity
            self.channel = channel
            self.amountText = amountText
            self.approved = approved
            self.graceDays = graceDays
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingChargeProposalView(_ item: PendingChargeProposal) -> PendingChargeProposalView {
        return PendingChargeProposalView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            maximumText: String(format: "%.2f", item.maximum),
            budget: String(format: "%.2f", item.budget),
            ratio: String(format: "%.2f", item.ratio),
            acuity: String(item.acuity),
            channel: item.channel,
            amountText: String(format: "%.2f", item.amount),
            approved: "\(item.approved)",
            graceDays: String(item.graceDays),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingChargeProposalViews(_ items: [PendingChargeProposal]) -> [PendingChargeProposalView] {
        var views: [PendingChargeProposalView] = []
        for item in items {
            views.append(toPendingChargeProposalView(item))
        }
        return views
    }

    static func sumPendingChargeProposalView(_ view: PendingChargeProposalView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMaximum + parsedBudget + parsedRatio
    }
}
