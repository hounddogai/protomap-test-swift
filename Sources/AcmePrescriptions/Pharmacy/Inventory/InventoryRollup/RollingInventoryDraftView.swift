import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling inventory draft.
    final class RollingInventoryDraftView {
        var codeText: String
        var labelText: String
        var archived: String
        var weight: String
        var approved: String
        var procedureCode: String
        var endsAt: String
        var revision: String
        var statusLabel: String

        init(codeText: String, labelText: String, archived: String, weight: String, approved: String, procedureCode: String, endsAt: String, revision: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.archived = archived
            self.weight = weight
            self.approved = approved
            self.procedureCode = procedureCode
            self.endsAt = endsAt
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toRollingInventoryDraftView(_ item: RollingInventoryDraft) -> RollingInventoryDraftView {
        return RollingInventoryDraftView(
            codeText: item.code,
            labelText: item.label,
            archived: "\(item.archived)",
            weight: String(format: "%.2f", item.weight),
            approved: "\(item.approved)",
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            endsAt: String(item.endsAt),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingInventoryDraftViews(_ items: [RollingInventoryDraft]) -> [RollingInventoryDraftView] {
        var views: [RollingInventoryDraftView] = []
        for item in items {
            views.append(toRollingInventoryDraftView(item))
        }
        return views
    }

    static func sumRollingInventoryDraftView(_ view: RollingInventoryDraftView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedWeight + Double(parsedEndsAt) + Double(parsedRevision)
    }
}
