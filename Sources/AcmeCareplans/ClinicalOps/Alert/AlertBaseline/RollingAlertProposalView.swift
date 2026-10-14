import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling alert proposal.
    final class RollingAlertProposalView {
        var code: String
        var title: String
        var diagnosisCode: String
        var reviewerText: String
        var endsAt: String
        var source: String
        var encounterID: String
        var statusLabel: String

        init(code: String, title: String, diagnosisCode: String, reviewerText: String, endsAt: String, source: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.reviewerText = reviewerText
            self.endsAt = endsAt
            self.source = source
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAlertProposalView(_ item: RollingAlertProposal) -> RollingAlertProposalView {
        return RollingAlertProposalView(
            code: item.code,
            title: item.title,
            diagnosisCode: item.diagnosisCode,
            reviewerText: item.reviewer,
            endsAt: String(item.endsAt),
            source: item.source,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAlertProposalViews(_ items: [RollingAlertProposal]) -> [RollingAlertProposalView] {
        var views: [RollingAlertProposalView] = []
        for item in items {
            views.append(toRollingAlertProposalView(item))
        }
        return views
    }

    static func sumRollingAlertProposalView(_ view: RollingAlertProposalView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
