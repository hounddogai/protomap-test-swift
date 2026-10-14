import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling panel preference.
    final class RollingPanelPreferenceView {
        var code: String
        var label: String
        var maximumText: String
        var contactEmail: String
        var floorValue: String
        var bed: String
        var statusLabel: String

        init(code: String, label: String, maximumText: String, contactEmail: String, floorValue: String, bed: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.maximumText = maximumText
            self.contactEmail = contactEmail
            self.floorValue = floorValue
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toRollingPanelPreferenceView(_ item: RollingPanelPreference) -> RollingPanelPreferenceView {
        return RollingPanelPreferenceView(
            code: item.code,
            label: item.label,
            maximumText: String(format: "%.2f", item.maximum),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            bed: Kit.Text.truncate(item.bed, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingPanelPreferenceViews(_ items: [RollingPanelPreference]) -> [RollingPanelPreferenceView] {
        var views: [RollingPanelPreferenceView] = []
        for item in items {
            views.append(toRollingPanelPreferenceView(item))
        }
        return views
    }

    static func sumRollingPanelPreferenceView(_ view: RollingPanelPreferenceView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedMaximum + parsedFloorValue
    }
}
