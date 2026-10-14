import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a capped handoff proposal.
    final class CappedHandoffProposalView {
        var code: String
        var titleText: String
        var procedureCodeText: String
        var encounterID: String
        var graceDays: String
        var attempts: String
        var statusLabel: String

        init(code: String, titleText: String, procedureCodeText: String, encounterID: String, graceDays: String, attempts: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.procedureCodeText = procedureCodeText
            self.encounterID = encounterID
            self.graceDays = graceDays
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toCappedHandoffProposalView(_ item: CappedHandoffProposal) -> CappedHandoffProposalView {
        return CappedHandoffProposalView(
            code: item.code,
            titleText: item.title,
            procedureCodeText: item.procedureCode,
            encounterID: item.encounterID,
            graceDays: String(item.graceDays),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedHandoffProposalViews(_ items: [CappedHandoffProposal]) -> [CappedHandoffProposalView] {
        var views: [CappedHandoffProposalView] = []
        for item in items {
            views.append(toCappedHandoffProposalView(item))
        }
        return views
    }

    static func sumCappedHandoffProposalView(_ view: CappedHandoffProposalView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedAttempts)
    }
}
