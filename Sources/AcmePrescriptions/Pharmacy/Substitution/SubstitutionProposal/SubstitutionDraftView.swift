import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution draft.
    final class SubstitutionDraftView {
        var code: String
        var nameText: String
        var notes: String
        var summary: String
        var endsAt: String
        var updatedAt: String
        var encounterIDText: String
        var ratio: String
        var limit: String
        var score: String
        var labelText: String
        var statusLabel: String

        init(code: String, nameText: String, notes: String, summary: String, endsAt: String, updatedAt: String, encounterIDText: String, ratio: String, limit: String, score: String, labelText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.notes = notes
            self.summary = summary
            self.endsAt = endsAt
            self.updatedAt = updatedAt
            self.encounterIDText = encounterIDText
            self.ratio = ratio
            self.limit = limit
            self.score = score
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionDraftView(_ item: SubstitutionDraft) -> SubstitutionDraftView {
        return SubstitutionDraftView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            notes: item.notes,
            summary: item.summary,
            endsAt: String(item.endsAt),
            updatedAt: String(item.updatedAt),
            encounterIDText: item.encounterID,
            ratio: String(format: "%.2f", item.ratio),
            limit: String(item.limit),
            score: String(format: "%.2f", item.score),
            labelText: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionDraftViews(_ items: [SubstitutionDraft]) -> [SubstitutionDraftView] {
        var views: [SubstitutionDraftView] = []
        for item in items {
            views.append(toSubstitutionDraftView(item))
        }
        return views
    }

    static func sumSubstitutionDraftView(_ view: SubstitutionDraftView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedUpdatedAt) + parsedRatio
    }
}
