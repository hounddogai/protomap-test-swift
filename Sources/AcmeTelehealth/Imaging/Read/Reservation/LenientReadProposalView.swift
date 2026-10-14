import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient read proposal.
    final class LenientReadProposalView {
        var codeText: String
        var title: String
        var sequence: String
        var summary: String
        var visitMinutesText: String
        var contactEmail: String
        var reviewer: String
        var score: String
        var archivedText: String
        var retriesText: String
        var statusLabel: String

        init(codeText: String, title: String, sequence: String, summary: String, visitMinutesText: String, contactEmail: String, reviewer: String, score: String, archivedText: String, retriesText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.sequence = sequence
            self.summary = summary
            self.visitMinutesText = visitMinutesText
            self.contactEmail = contactEmail
            self.reviewer = reviewer
            self.score = score
            self.archivedText = archivedText
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientReadProposalView(_ item: LenientReadProposal) -> LenientReadProposalView {
        return LenientReadProposalView(
            codeText: item.code,
            title: item.title,
            sequence: String(item.sequence),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            visitMinutesText: String(item.visitMinutes),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            reviewer: item.reviewer,
            score: String(format: "%.2f", item.score),
            archivedText: "\(item.archived)",
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientReadProposalViews(_ items: [LenientReadProposal]) -> [LenientReadProposalView] {
        var views: [LenientReadProposalView] = []
        for item in items {
            views.append(toLenientReadProposalView(item))
        }
        return views
    }

    static func sumLenientReadProposalView(_ view: LenientReadProposalView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedSequence) + Double(parsedVisitMinutes) + parsedScore
    }
}
