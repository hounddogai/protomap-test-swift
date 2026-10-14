import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a weighted transfer request.
    final class WeightedTransferRequestView {
        var code: String
        var label: String
        var clinicianIDText: String
        var floorValue: String
        var descriptionText: String
        var priority: String
        var payer: String
        var locale: String
        var statusLabel: String

        init(code: String, label: String, clinicianIDText: String, floorValue: String, descriptionText: String, priority: String, payer: String, locale: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.clinicianIDText = clinicianIDText
            self.floorValue = floorValue
            self.descriptionText = descriptionText
            self.priority = priority
            self.payer = payer
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedTransferRequestView(_ item: WeightedTransferRequest) -> WeightedTransferRequestView {
        return WeightedTransferRequestView(
            code: item.code,
            label: item.label,
            clinicianIDText: item.clinicianID,
            floorValue: String(format: "%.2f", item.floorValue),
            descriptionText: Kit.Text.truncate(item.description, limit: 80),
            priority: String(item.priority),
            payer: item.payer,
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedTransferRequestViews(_ items: [WeightedTransferRequest]) -> [WeightedTransferRequestView] {
        var views: [WeightedTransferRequestView] = []
        for item in items {
            views.append(toWeightedTransferRequestView(item))
        }
        return views
    }

    static func sumWeightedTransferRequestView(_ view: WeightedTransferRequestView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedFloorValue + Double(parsedPriority)
    }
}
