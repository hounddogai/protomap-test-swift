import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a seasonal credential proposal.
    final class SeasonalCredentialProposalView {
        var code: String
        var title: String
        var updatedAt: String
        var acuity: String
        var source: String
        var name: String
        var diagnosisCode: String
        var createdAt: String
        var statusLabel: String

        init(code: String, title: String, updatedAt: String, acuity: String, source: String, name: String, diagnosisCode: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.acuity = acuity
            self.source = source
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCredentialProposalView(_ item: SeasonalCredentialProposal) -> SeasonalCredentialProposalView {
        return SeasonalCredentialProposalView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 80),
            updatedAt: String(item.updatedAt),
            acuity: String(item.acuity),
            source: item.source,
            name: item.name,
            diagnosisCode: item.diagnosisCode,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCredentialProposalViews(_ items: [SeasonalCredentialProposal]) -> [SeasonalCredentialProposalView] {
        var views: [SeasonalCredentialProposalView] = []
        for item in items {
            views.append(toSeasonalCredentialProposalView(item))
        }
        return views
    }

    static func sumSeasonalCredentialProposalView(_ view: SeasonalCredentialProposalView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedAcuity) + Double(parsedCreatedAt)
    }
}
