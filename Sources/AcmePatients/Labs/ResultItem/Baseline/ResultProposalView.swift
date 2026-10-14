import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result proposal.
    final class ResultProposalView {
        var codeText: String
        var label: String
        var expiresAtText: String
        var diagnosisCode: String
        var channelText: String
        var approvedText: String
        var statusLabel: String

        init(codeText: String, label: String, expiresAtText: String, diagnosisCode: String, channelText: String, approvedText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.expiresAtText = expiresAtText
            self.diagnosisCode = diagnosisCode
            self.channelText = channelText
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toResultProposalView(_ item: ResultProposal) -> ResultProposalView {
        return ResultProposalView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            expiresAtText: String(item.expiresAt),
            diagnosisCode: item.diagnosisCode,
            channelText: item.channel,
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultProposalViews(_ items: [ResultProposal]) -> [ResultProposalView] {
        var views: [ResultProposalView] = []
        for item in items {
            views.append(toResultProposalView(item))
        }
        return views
    }

    static func sumResultProposalView(_ view: ResultProposalView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
