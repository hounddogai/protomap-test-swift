import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board proposal.
    final class BedBoardProposalView {
        var codeText: String
        var label: String
        var revision: String
        var regionText: String
        var discountText: String
        var timezoneText: String
        var payerText: String
        var thresholdText: String
        var checksum: String
        var statusLabel: String

        init(codeText: String, label: String, revision: String, regionText: String, discountText: String, timezoneText: String, payerText: String, thresholdText: String, checksum: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.revision = revision
            self.regionText = regionText
            self.discountText = discountText
            self.timezoneText = timezoneText
            self.payerText = payerText
            self.thresholdText = thresholdText
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardProposalView(_ item: BedBoardProposal) -> BedBoardProposalView {
        return BedBoardProposalView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            revision: String(item.revision),
            regionText: item.region,
            discountText: String(format: "%.2f", item.discount),
            timezoneText: item.timezone,
            payerText: item.payer,
            thresholdText: String(format: "%.2f", item.threshold),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardProposalViews(_ items: [BedBoardProposal]) -> [BedBoardProposalView] {
        var views: [BedBoardProposalView] = []
        for item in items {
            views.append(toBedBoardProposalView(item))
        }
        return views
    }

    static func sumBedBoardProposalView(_ view: BedBoardProposalView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedRevision) + parsedDiscount + parsedThreshold
    }
}
