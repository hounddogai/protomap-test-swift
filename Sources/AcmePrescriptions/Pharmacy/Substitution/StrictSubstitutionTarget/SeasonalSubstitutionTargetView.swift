import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a seasonal substitution target.
    final class SeasonalSubstitutionTargetView {
        var codeText: String
        var label: String
        var phone: String
        var facilityText: String
        var bed: String
        var endsAt: String
        var notes: String
        var region: String
        var refills: String
        var ownerID: String
        var encounterIDText: String
        var statusLabel: String

        init(codeText: String, label: String, phone: String, facilityText: String, bed: String, endsAt: String, notes: String, region: String, refills: String, ownerID: String, encounterIDText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.phone = phone
            self.facilityText = facilityText
            self.bed = bed
            self.endsAt = endsAt
            self.notes = notes
            self.region = region
            self.refills = refills
            self.ownerID = ownerID
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSubstitutionTargetView(_ item: SeasonalSubstitutionTarget) -> SeasonalSubstitutionTargetView {
        return SeasonalSubstitutionTargetView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            phone: item.phone,
            facilityText: item.facility,
            bed: item.bed,
            endsAt: String(item.endsAt),
            notes: item.notes,
            region: item.region,
            refills: String(item.refills),
            ownerID: item.ownerID,
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSubstitutionTargetViews(_ items: [SeasonalSubstitutionTarget]) -> [SeasonalSubstitutionTargetView] {
        var views: [SeasonalSubstitutionTargetView] = []
        for item in items {
            views.append(toSeasonalSubstitutionTargetView(item))
        }
        return views
    }

    static func sumSeasonalSubstitutionTargetView(_ view: SeasonalSubstitutionTargetView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedRefills)
    }
}
