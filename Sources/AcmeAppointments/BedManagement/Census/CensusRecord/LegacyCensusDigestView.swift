import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy census digest.
    final class LegacyCensusDigestView {
        var codeText: String
        var labelText: String
        var active: String
        var expiresAt: String
        var title: String
        var budget: String
        var segmentText: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, labelText: String, active: String, expiresAt: String, title: String, budget: String, segmentText: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.active = active
            self.expiresAt = expiresAt
            self.title = title
            self.budget = budget
            self.segmentText = segmentText
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCensusDigestView(_ item: LegacyCensusDigest) -> LegacyCensusDigestView {
        return LegacyCensusDigestView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            active: "\(item.active)",
            expiresAt: String(item.expiresAt),
            title: item.title,
            budget: String(format: "%.2f", item.budget),
            segmentText: Kit.Text.truncate(item.segment, limit: 120),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCensusDigestViews(_ items: [LegacyCensusDigest]) -> [LegacyCensusDigestView] {
        var views: [LegacyCensusDigestView] = []
        for item in items {
            views.append(toLegacyCensusDigestView(item))
        }
        return views
    }

    static func sumLegacyCensusDigestView(_ view: LegacyCensusDigestView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedExpiresAt) + parsedBudget
    }
}
