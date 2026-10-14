import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense adjustment.
    final class DispenseAdjustmentView {
        var code: String
        var name: String
        var contactEmailText: String
        var encounterIDText: String
        var endsAt: String
        var ward: String
        var statusLabel: String

        init(code: String, name: String, contactEmailText: String, encounterIDText: String, endsAt: String, ward: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.contactEmailText = contactEmailText
            self.encounterIDText = encounterIDText
            self.endsAt = endsAt
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseAdjustmentView(_ item: DispenseAdjustment) -> DispenseAdjustmentView {
        return DispenseAdjustmentView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            contactEmailText: item.contactEmail,
            encounterIDText: item.encounterID,
            endsAt: String(item.endsAt),
            ward: Kit.Text.truncate(item.ward, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseAdjustmentViews(_ items: [DispenseAdjustment]) -> [DispenseAdjustmentView] {
        var views: [DispenseAdjustmentView] = []
        for item in items {
            views.append(toDispenseAdjustmentView(item))
        }
        return views
    }

    static func sumDispenseAdjustmentView(_ view: DispenseAdjustmentView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
