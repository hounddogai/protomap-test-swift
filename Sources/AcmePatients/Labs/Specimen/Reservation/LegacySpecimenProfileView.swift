import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy specimen profile.
    final class LegacySpecimenProfileView {
        var codeText: String
        var labelText: String
        var costText: String
        var acuity: String
        var minimum: String
        var limit: String
        var ownerID: String
        var nameText: String
        var budget: String
        var clinicianIDText: String
        var endsAtText: String
        var statusLabel: String

        init(codeText: String, labelText: String, costText: String, acuity: String, minimum: String, limit: String, ownerID: String, nameText: String, budget: String, clinicianIDText: String, endsAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.costText = costText
            self.acuity = acuity
            self.minimum = minimum
            self.limit = limit
            self.ownerID = ownerID
            self.nameText = nameText
            self.budget = budget
            self.clinicianIDText = clinicianIDText
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacySpecimenProfileView(_ item: LegacySpecimenProfile) -> LegacySpecimenProfileView {
        return LegacySpecimenProfileView(
            codeText: item.code,
            labelText: item.label,
            costText: String(format: "%.2f", item.cost),
            acuity: String(item.acuity),
            minimum: String(format: "%.2f", item.minimum),
            limit: String(item.limit),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            nameText: item.name,
            budget: String(format: "%.2f", item.budget),
            clinicianIDText: item.clinicianID,
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacySpecimenProfileViews(_ items: [LegacySpecimenProfile]) -> [LegacySpecimenProfileView] {
        var views: [LegacySpecimenProfileView] = []
        for item in items {
            views.append(toLegacySpecimenProfileView(item))
        }
        return views
    }

    static func sumLegacySpecimenProfileView(_ view: LegacySpecimenProfileView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedCost + Double(parsedAcuity) + parsedMinimum
    }
}
