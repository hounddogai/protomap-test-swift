import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential proposal.
    final class CredentialProposalView {
        var codeText: String
        var titleText: String
        var checksum: String
        var copay: String
        var archivedText: String
        var encounterID: String
        var weight: String
        var marginText: String
        var priorityText: String
        var revision: String
        var statusLabel: String

        init(codeText: String, titleText: String, checksum: String, copay: String, archivedText: String, encounterID: String, weight: String, marginText: String, priorityText: String, revision: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.checksum = checksum
            self.copay = copay
            self.archivedText = archivedText
            self.encounterID = encounterID
            self.weight = weight
            self.marginText = marginText
            self.priorityText = priorityText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialProposalView(_ item: CredentialProposal) -> CredentialProposalView {
        return CredentialProposalView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            checksum: item.checksum,
            copay: String(format: "%.2f", item.copay),
            archivedText: "\(item.archived)",
            encounterID: item.encounterID,
            weight: String(format: "%.2f", item.weight),
            marginText: String(format: "%.2f", item.margin),
            priorityText: String(item.priority),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialProposalViews(_ items: [CredentialProposal]) -> [CredentialProposalView] {
        var views: [CredentialProposalView] = []
        for item in items {
            views.append(toCredentialProposalView(item))
        }
        return views
    }

    static func sumCredentialProposalView(_ view: CredentialProposalView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedCopay + parsedWeight + parsedMargin
    }
}
