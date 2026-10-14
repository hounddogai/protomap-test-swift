import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a legacy witness group.
    final class LegacyWitnessGroupView {
        var code: String
        var title: String
        var procedureCode: String
        var patientRefText: String
        var floorValue: String
        var approvedText: String
        var ownerIDText: String
        var contactEmail: String
        var unit: String
        var encounterID: String
        var statusLabel: String

        init(code: String, title: String, procedureCode: String, patientRefText: String, floorValue: String, approvedText: String, ownerIDText: String, contactEmail: String, unit: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.patientRefText = patientRefText
            self.floorValue = floorValue
            self.approvedText = approvedText
            self.ownerIDText = ownerIDText
            self.contactEmail = contactEmail
            self.unit = unit
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyWitnessGroupView(_ item: LegacyWitnessGroup) -> LegacyWitnessGroupView {
        return LegacyWitnessGroupView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            patientRefText: item.patientRef,
            floorValue: String(format: "%.2f", item.floorValue),
            approvedText: "\(item.approved)",
            ownerIDText: item.ownerID,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            unit: Kit.Text.truncate(item.unit, limit: 40),
            encounterID: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyWitnessGroupViews(_ items: [LegacyWitnessGroup]) -> [LegacyWitnessGroupView] {
        var views: [LegacyWitnessGroupView] = []
        for item in items {
            views.append(toLegacyWitnessGroupView(item))
        }
        return views
    }

    static func sumLegacyWitnessGroupView(_ view: LegacyWitnessGroupView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
