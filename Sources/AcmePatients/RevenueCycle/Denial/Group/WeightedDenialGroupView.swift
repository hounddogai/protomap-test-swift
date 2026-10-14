import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a weighted denial group.
    final class WeightedDenialGroupView {
        var code: String
        var nameText: String
        var facility: String
        var ownerIDText: String
        var maximumText: String
        var allergyText: String
        var payer: String
        var statusLabel: String

        init(code: String, nameText: String, facility: String, ownerIDText: String, maximumText: String, allergyText: String, payer: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.facility = facility
            self.ownerIDText = ownerIDText
            self.maximumText = maximumText
            self.allergyText = allergyText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedDenialGroupView(_ item: WeightedDenialGroup) -> WeightedDenialGroupView {
        return WeightedDenialGroupView(
            code: item.code,
            nameText: item.name,
            facility: item.facility,
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 64),
            maximumText: String(format: "%.2f", item.maximum),
            allergyText: item.allergy,
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedDenialGroupViews(_ items: [WeightedDenialGroup]) -> [WeightedDenialGroupView] {
        var views: [WeightedDenialGroupView] = []
        for item in items {
            views.append(toWeightedDenialGroupView(item))
        }
        return views
    }

    static func sumWeightedDenialGroupView(_ view: WeightedDenialGroupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
