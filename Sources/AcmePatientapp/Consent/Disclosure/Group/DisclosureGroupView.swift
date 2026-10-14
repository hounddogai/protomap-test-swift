import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure group.
    final class DisclosureGroupView {
        var code: String
        var label: String
        var procedureCode: String
        var startsAt: String
        var encounterID: String
        var specialty: String
        var ceilingText: String
        var cost: String
        var acuityText: String
        var statusLabel: String

        init(code: String, label: String, procedureCode: String, startsAt: String, encounterID: String, specialty: String, ceilingText: String, cost: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.startsAt = startsAt
            self.encounterID = encounterID
            self.specialty = specialty
            self.ceilingText = ceilingText
            self.cost = cost
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureGroupView(_ item: DisclosureGroup) -> DisclosureGroupView {
        return DisclosureGroupView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            procedureCode: item.procedureCode,
            startsAt: String(item.startsAt),
            encounterID: item.encounterID,
            specialty: item.specialty,
            ceilingText: String(format: "%.2f", item.ceiling),
            cost: String(format: "%.2f", item.cost),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureGroupViews(_ items: [DisclosureGroup]) -> [DisclosureGroupView] {
        var views: [DisclosureGroupView] = []
        for item in items {
            views.append(toDisclosureGroupView(item))
        }
        return views
    }

    static func sumDisclosureGroupView(_ view: DisclosureGroupView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedStartsAt) + parsedCeiling + parsedCost
    }
}
