import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual program override.
    final class ManualProgramOverrideView {
        var code: String
        var nameText: String
        var allergyText: String
        var localeText: String
        var ward: String
        var quantity: String
        var statusLabel: String

        init(code: String, nameText: String, allergyText: String, localeText: String, ward: String, quantity: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.allergyText = allergyText
            self.localeText = localeText
            self.ward = ward
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toManualProgramOverrideView(_ item: ManualProgramOverride) -> ManualProgramOverrideView {
        return ManualProgramOverrideView(
            code: item.code,
            nameText: item.name,
            allergyText: item.allergy,
            localeText: item.locale,
            ward: item.ward,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualProgramOverrideViews(_ items: [ManualProgramOverride]) -> [ManualProgramOverrideView] {
        var views: [ManualProgramOverrideView] = []
        for item in items {
            views.append(toManualProgramOverrideView(item))
        }
        return views
    }

    static func sumManualProgramOverrideView(_ view: ManualProgramOverrideView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
