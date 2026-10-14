import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a tiered interaction draft.
    final class TieredInteractionDraftView {
        var codeText: String
        var title: String
        var createdAt: String
        var reviewer: String
        var payer: String
        var minimum: String
        var ownerID: String
        var revision: String
        var name: String
        var statusLabel: String

        init(codeText: String, title: String, createdAt: String, reviewer: String, payer: String, minimum: String, ownerID: String, revision: String, name: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.createdAt = createdAt
            self.reviewer = reviewer
            self.payer = payer
            self.minimum = minimum
            self.ownerID = ownerID
            self.revision = revision
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toTieredInteractionDraftView(_ item: TieredInteractionDraft) -> TieredInteractionDraftView {
        return TieredInteractionDraftView(
            codeText: item.code,
            title: item.title,
            createdAt: String(item.createdAt),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            payer: item.payer,
            minimum: String(format: "%.2f", item.minimum),
            ownerID: item.ownerID,
            revision: String(item.revision),
            name: Kit.Text.truncate(item.name, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredInteractionDraftViews(_ items: [TieredInteractionDraft]) -> [TieredInteractionDraftView] {
        var views: [TieredInteractionDraftView] = []
        for item in items {
            views.append(toTieredInteractionDraftView(item))
        }
        return views
    }

    static func sumTieredInteractionDraftView(_ view: TieredInteractionDraftView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedCreatedAt) + parsedMinimum + Double(parsedRevision)
    }
}
