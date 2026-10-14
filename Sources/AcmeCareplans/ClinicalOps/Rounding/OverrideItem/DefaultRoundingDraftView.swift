import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a default rounding draft.
    final class DefaultRoundingDraftView {
        var codeText: String
        var label: String
        var revision: String
        var descriptionText: String
        var clinicianID: String
        var encounterIDText: String
        var active: String
        var statusLabel: String

        init(codeText: String, label: String, revision: String, descriptionText: String, clinicianID: String, encounterIDText: String, active: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.revision = revision
            self.descriptionText = descriptionText
            self.clinicianID = clinicianID
            self.encounterIDText = encounterIDText
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRoundingDraftView(_ item: DefaultRoundingDraft) -> DefaultRoundingDraftView {
        return DefaultRoundingDraftView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            revision: String(item.revision),
            descriptionText: item.description,
            clinicianID: item.clinicianID,
            encounterIDText: item.encounterID,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRoundingDraftViews(_ items: [DefaultRoundingDraft]) -> [DefaultRoundingDraftView] {
        var views: [DefaultRoundingDraftView] = []
        for item in items {
            views.append(toDefaultRoundingDraftView(item))
        }
        return views
    }

    static func sumDefaultRoundingDraftView(_ view: DefaultRoundingDraftView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
