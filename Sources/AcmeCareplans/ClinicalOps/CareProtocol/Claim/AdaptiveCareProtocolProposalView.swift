import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive care protocol proposal.
    final class AdaptiveCareProtocolProposalView {
        var code: String
        var label: String
        var startsAt: String
        var sequence: String
        var revision: String
        var statusLabel: String

        init(code: String, label: String, startsAt: String, sequence: String, revision: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.sequence = sequence
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCareProtocolProposalView(_ item: AdaptiveCareProtocolProposal) -> AdaptiveCareProtocolProposalView {
        return AdaptiveCareProtocolProposalView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 40),
            startsAt: String(item.startsAt),
            sequence: String(item.sequence),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCareProtocolProposalViews(_ items: [AdaptiveCareProtocolProposal]) -> [AdaptiveCareProtocolProposalView] {
        var views: [AdaptiveCareProtocolProposalView] = []
        for item in items {
            views.append(toAdaptiveCareProtocolProposalView(item))
        }
        return views
    }

    static func sumAdaptiveCareProtocolProposalView(_ view: AdaptiveCareProtocolProposalView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedSequence) + Double(parsedRevision)
    }
}
