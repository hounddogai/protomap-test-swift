import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness proposal.
    final class WitnessProposalView {
        var code: String
        var title: String
        var priorityText: String
        var clinicianID: String
        var scoreText: String
        var name: String
        var contactEmailText: String
        var statusLabel: String

        init(code: String, title: String, priorityText: String, clinicianID: String, scoreText: String, name: String, contactEmailText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.priorityText = priorityText
            self.clinicianID = clinicianID
            self.scoreText = scoreText
            self.name = name
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessProposalView(_ item: WitnessProposal) -> WitnessProposalView {
        return WitnessProposalView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 64),
            priorityText: String(item.priority),
            clinicianID: item.clinicianID,
            scoreText: String(format: "%.2f", item.score),
            name: item.name,
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessProposalViews(_ items: [WitnessProposal]) -> [WitnessProposalView] {
        var views: [WitnessProposalView] = []
        for item in items {
            views.append(toWitnessProposalView(item))
        }
        return views
    }

    static func sumWitnessProposalView(_ view: WitnessProposalView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedPriority) + parsedScore
    }
}
