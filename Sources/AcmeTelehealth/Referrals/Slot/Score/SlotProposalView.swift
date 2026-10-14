import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot proposal.
    final class SlotProposalView {
        var code: String
        var title: String
        var ratioText: String
        var contactEmail: String
        var rate: String
        var ceilingText: String
        var maximumText: String
        var statusLabel: String

        init(code: String, title: String, ratioText: String, contactEmail: String, rate: String, ceilingText: String, maximumText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ratioText = ratioText
            self.contactEmail = contactEmail
            self.rate = rate
            self.ceilingText = ceilingText
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotProposalView(_ item: SlotProposal) -> SlotProposalView {
        return SlotProposalView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            ratioText: String(format: "%.2f", item.ratio),
            contactEmail: item.contactEmail,
            rate: String(format: "%.2f", item.rate),
            ceilingText: String(format: "%.2f", item.ceiling),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotProposalViews(_ items: [SlotProposal]) -> [SlotProposalView] {
        var views: [SlotProposalView] = []
        for item in items {
            views.append(toSlotProposalView(item))
        }
        return views
    }

    static func sumSlotProposalView(_ view: SlotProposalView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedRatio + parsedRate + parsedCeiling
    }
}
