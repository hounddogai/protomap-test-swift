import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional panel preference.
    final class RegionalPanelPreferenceView {
        var codeText: String
        var labelText: String
        var endsAtText: String
        var externalRef: String
        var patientRef: String
        var floorValueText: String
        var updatedAt: String
        var notes: String
        var ceiling: String
        var quantity: String
        var checksumText: String
        var statusLabel: String

        init(codeText: String, labelText: String, endsAtText: String, externalRef: String, patientRef: String, floorValueText: String, updatedAt: String, notes: String, ceiling: String, quantity: String, checksumText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.endsAtText = endsAtText
            self.externalRef = externalRef
            self.patientRef = patientRef
            self.floorValueText = floorValueText
            self.updatedAt = updatedAt
            self.notes = notes
            self.ceiling = ceiling
            self.quantity = quantity
            self.checksumText = checksumText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalPanelPreferenceView(_ item: RegionalPanelPreference) -> RegionalPanelPreferenceView {
        return RegionalPanelPreferenceView(
            codeText: item.code,
            labelText: item.label,
            endsAtText: String(item.endsAt),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            patientRef: item.patientRef,
            floorValueText: String(format: "%.2f", item.floorValue),
            updatedAt: String(item.updatedAt),
            notes: item.notes,
            ceiling: String(format: "%.2f", item.ceiling),
            quantity: String(item.quantity),
            checksumText: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalPanelPreferenceViews(_ items: [RegionalPanelPreference]) -> [RegionalPanelPreferenceView] {
        var views: [RegionalPanelPreferenceView] = []
        for item in items {
            views.append(toRegionalPanelPreferenceView(item))
        }
        return views
    }

    static func sumRegionalPanelPreferenceView(_ view: RegionalPanelPreferenceView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedEndsAt) + parsedFloorValue + Double(parsedUpdatedAt)
    }
}
