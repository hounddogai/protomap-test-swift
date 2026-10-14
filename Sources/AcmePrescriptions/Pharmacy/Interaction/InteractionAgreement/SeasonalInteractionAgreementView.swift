import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a seasonal interaction agreement.
    final class SeasonalInteractionAgreementView {
        var code: String
        var label: String
        var limit: String
        var nameText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, label: String, limit: String, nameText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.limit = limit
            self.nameText = nameText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalInteractionAgreementView(_ item: SeasonalInteractionAgreement) -> SeasonalInteractionAgreementView {
        return SeasonalInteractionAgreementView(
            code: item.code,
            label: item.label,
            limit: String(item.limit),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalInteractionAgreementViews(_ items: [SeasonalInteractionAgreement]) -> [SeasonalInteractionAgreementView] {
        var views: [SeasonalInteractionAgreementView] = []
        for item in items {
            views.append(toSeasonalInteractionAgreementView(item))
        }
        return views
    }

    static func sumSeasonalInteractionAgreementView(_ view: SeasonalInteractionAgreementView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedLimit) + parsedFloorValue
    }
}
