import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled revocation digest.
    final class ScheduledRevocationDigestView {
        var code: String
        var nameText: String
        var notesText: String
        var startsAt: String
        var unit: String
        var minimum: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, nameText: String, notesText: String, startsAt: String, unit: String, minimum: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.notesText = notesText
            self.startsAt = startsAt
            self.unit = unit
            self.minimum = minimum
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledRevocationDigestView(_ item: ScheduledRevocationDigest) -> ScheduledRevocationDigestView {
        return ScheduledRevocationDigestView(
            code: item.code,
            nameText: item.name,
            notesText: item.notes,
            startsAt: String(item.startsAt),
            unit: Kit.Text.truncate(item.unit, limit: 80),
            minimum: String(format: "%.2f", item.minimum),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledRevocationDigestViews(_ items: [ScheduledRevocationDigest]) -> [ScheduledRevocationDigestView] {
        var views: [ScheduledRevocationDigestView] = []
        for item in items {
            views.append(toScheduledRevocationDigestView(item))
        }
        return views
    }

    static func sumScheduledRevocationDigestView(_ view: ScheduledRevocationDigestView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedStartsAt) + parsedMinimum
    }
}
