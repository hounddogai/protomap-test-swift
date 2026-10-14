import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending formulary proposal.
    final class PendingFormularyProposalView {
        var code: String
        var titleText: String
        var batchSize: String
        var externalRef: String
        var reviewerText: String
        var source: String
        var channel: String
        var statusLabel: String

        init(code: String, titleText: String, batchSize: String, externalRef: String, reviewerText: String, source: String, channel: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.batchSize = batchSize
            self.externalRef = externalRef
            self.reviewerText = reviewerText
            self.source = source
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toPendingFormularyProposalView(_ item: PendingFormularyProposal) -> PendingFormularyProposalView {
        return PendingFormularyProposalView(
            code: item.code,
            titleText: item.title,
            batchSize: String(item.batchSize),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            reviewerText: item.reviewer,
            source: Kit.Text.truncate(item.source, limit: 80),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingFormularyProposalViews(_ items: [PendingFormularyProposal]) -> [PendingFormularyProposalView] {
        var views: [PendingFormularyProposalView] = []
        for item in items {
            views.append(toPendingFormularyProposalView(item))
        }
        return views
    }

    static func sumPendingFormularyProposalView(_ view: PendingFormularyProposalView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
