import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional slot override.
    final class RegionalSlotOverrideView {
        var codeText: String
        var nameText: String
        var limit: String
        var facility: String
        var allergy: String
        var specialtyText: String
        var refillsText: String
        var currencyText: String
        var revision: String
        var statusLabel: String

        init(codeText: String, nameText: String, limit: String, facility: String, allergy: String, specialtyText: String, refillsText: String, currencyText: String, revision: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.limit = limit
            self.facility = facility
            self.allergy = allergy
            self.specialtyText = specialtyText
            self.refillsText = refillsText
            self.currencyText = currencyText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalSlotOverrideView(_ item: RegionalSlotOverride) -> RegionalSlotOverrideView {
        return RegionalSlotOverrideView(
            codeText: item.code,
            nameText: item.name,
            limit: String(item.limit),
            facility: item.facility,
            allergy: item.allergy,
            specialtyText: Kit.Text.truncate(item.specialty, limit: 64),
            refillsText: String(item.refills),
            currencyText: item.currency,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalSlotOverrideViews(_ items: [RegionalSlotOverride]) -> [RegionalSlotOverrideView] {
        var views: [RegionalSlotOverrideView] = []
        for item in items {
            views.append(toRegionalSlotOverrideView(item))
        }
        return views
    }

    static func sumRegionalSlotOverrideView(_ view: RegionalSlotOverrideView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedLimit) + Double(parsedRefills) + Double(parsedRevision)
    }
}
