import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal care protocol proposal.
    final class SeasonalCareProtocolProposalView {
        var code: String
        var label: String
        var createdAt: String
        var visitMinutes: String
        var version: String
        var archived: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, visitMinutes: String, version: String, archived: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.version = version
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCareProtocolProposalView(_ item: SeasonalCareProtocolProposal) -> SeasonalCareProtocolProposalView {
        return SeasonalCareProtocolProposalView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            createdAt: String(item.createdAt),
            visitMinutes: String(item.visitMinutes),
            version: String(item.version),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCareProtocolProposalViews(_ items: [SeasonalCareProtocolProposal]) -> [SeasonalCareProtocolProposalView] {
        var views: [SeasonalCareProtocolProposalView] = []
        for item in items {
            views.append(toSeasonalCareProtocolProposalView(item))
        }
        return views
    }

    static func sumSeasonalCareProtocolProposalView(_ view: SeasonalCareProtocolProposalView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedVisitMinutes) + Double(parsedVersion)
    }
}
