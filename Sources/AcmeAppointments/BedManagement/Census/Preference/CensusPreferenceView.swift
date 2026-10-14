import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census preference.
    final class CensusPreferenceView {
        var code: String
        var title: String
        var procedureCodeText: String
        var visibleText: String
        var archivedText: String
        var timezone: String
        var floorValue: String
        var label: String
        var ward: String
        var statusLabel: String

        init(code: String, title: String, procedureCodeText: String, visibleText: String, archivedText: String, timezone: String, floorValue: String, label: String, ward: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCodeText = procedureCodeText
            self.visibleText = visibleText
            self.archivedText = archivedText
            self.timezone = timezone
            self.floorValue = floorValue
            self.label = label
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toCensusPreferenceView(_ item: CensusPreference) -> CensusPreferenceView {
        return CensusPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 40),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 40),
            visibleText: "\(item.visible)",
            archivedText: "\(item.archived)",
            timezone: item.timezone,
            floorValue: String(format: "%.2f", item.floorValue),
            label: item.label,
            ward: Kit.Text.truncate(item.ward, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusPreferenceViews(_ items: [CensusPreference]) -> [CensusPreferenceView] {
        var views: [CensusPreferenceView] = []
        for item in items {
            views.append(toCensusPreferenceView(item))
        }
        return views
    }

    static func sumCensusPreferenceView(_ view: CensusPreferenceView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
