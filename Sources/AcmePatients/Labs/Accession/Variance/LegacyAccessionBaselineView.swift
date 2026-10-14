import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy accession baseline.
    final class LegacyAccessionBaselineView {
        var code: String
        var name: String
        var unitText: String
        var checksum: String
        var active: String
        var specialty: String
        var encounterID: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, unitText: String, checksum: String, active: String, specialty: String, encounterID: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.unitText = unitText
            self.checksum = checksum
            self.active = active
            self.specialty = specialty
            self.encounterID = encounterID
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAccessionBaselineView(_ item: LegacyAccessionBaseline) -> LegacyAccessionBaselineView {
        return LegacyAccessionBaselineView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            unitText: item.unit,
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            active: "\(item.active)",
            specialty: item.specialty,
            encounterID: item.encounterID,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAccessionBaselineViews(_ items: [LegacyAccessionBaseline]) -> [LegacyAccessionBaselineView] {
        var views: [LegacyAccessionBaselineView] = []
        for item in items {
            views.append(toLegacyAccessionBaselineView(item))
        }
        return views
    }

    static func sumLegacyAccessionBaselineView(_ view: LegacyAccessionBaselineView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
