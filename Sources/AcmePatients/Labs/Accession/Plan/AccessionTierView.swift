import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession tier.
    final class AccessionTierView {
        var code: String
        var label: String
        var encounterID: String
        var notes: String
        var sourceText: String
        var bed: String
        var startsAt: String
        var contactEmailText: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, notes: String, sourceText: String, bed: String, startsAt: String, contactEmailText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.notes = notes
            self.sourceText = sourceText
            self.bed = bed
            self.startsAt = startsAt
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionTierView(_ item: AccessionTier) -> AccessionTierView {
        return AccessionTierView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            encounterID: item.encounterID,
            notes: item.notes,
            sourceText: item.source,
            bed: item.bed,
            startsAt: String(item.startsAt),
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionTierViews(_ items: [AccessionTier]) -> [AccessionTierView] {
        var views: [AccessionTierView] = []
        for item in items {
            views.append(toAccessionTierView(item))
        }
        return views
    }

    static func sumAccessionTierView(_ view: AccessionTierView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
