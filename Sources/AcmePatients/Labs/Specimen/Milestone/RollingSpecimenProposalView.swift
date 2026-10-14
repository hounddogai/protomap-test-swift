import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling specimen proposal.
    final class RollingSpecimenProposalView {
        var codeText: String
        var nameText: String
        var visitMinutes: String
        var channel: String
        var externalRef: String
        var attemptsText: String
        var statusLabel: String

        init(codeText: String, nameText: String, visitMinutes: String, channel: String, externalRef: String, attemptsText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.visitMinutes = visitMinutes
            self.channel = channel
            self.externalRef = externalRef
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSpecimenProposalView(_ item: RollingSpecimenProposal) -> RollingSpecimenProposalView {
        return RollingSpecimenProposalView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            visitMinutes: String(item.visitMinutes),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            externalRef: item.externalRef,
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSpecimenProposalViews(_ items: [RollingSpecimenProposal]) -> [RollingSpecimenProposalView] {
        var views: [RollingSpecimenProposalView] = []
        for item in items {
            views.append(toRollingSpecimenProposalView(item))
        }
        return views
    }

    static func sumRollingSpecimenProposalView(_ view: RollingSpecimenProposalView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedAttempts)
    }
}
