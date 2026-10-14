import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary credential proposal.
    final class PrimaryCredentialProposalView {
        var codeText: String
        var nameText: String
        var segmentText: String
        var facility: String
        var retriesText: String
        var endsAt: String
        var patientRefText: String
        var notes: String
        var statusLabel: String

        init(codeText: String, nameText: String, segmentText: String, facility: String, retriesText: String, endsAt: String, patientRefText: String, notes: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.segmentText = segmentText
            self.facility = facility
            self.retriesText = retriesText
            self.endsAt = endsAt
            self.patientRefText = patientRefText
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCredentialProposalView(_ item: PrimaryCredentialProposal) -> PrimaryCredentialProposalView {
        return PrimaryCredentialProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            segmentText: item.segment,
            facility: item.facility,
            retriesText: String(item.retries),
            endsAt: String(item.endsAt),
            patientRefText: item.patientRef,
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCredentialProposalViews(_ items: [PrimaryCredentialProposal]) -> [PrimaryCredentialProposalView] {
        var views: [PrimaryCredentialProposalView] = []
        for item in items {
            views.append(toPrimaryCredentialProposalView(item))
        }
        return views
    }

    static func sumPrimaryCredentialProposalView(_ view: PrimaryCredentialProposalView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedRetries) + Double(parsedEndsAt)
    }
}
