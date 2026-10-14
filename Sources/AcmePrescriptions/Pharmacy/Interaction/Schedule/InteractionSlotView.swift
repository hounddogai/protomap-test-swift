import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction slot.
    final class InteractionSlotView {
        var code: String
        var name: String
        var encounterIDText: String
        var batchSize: String
        var unit: String
        var discountText: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(code: String, name: String, encounterIDText: String, batchSize: String, unit: String, discountText: String, diagnosisCodeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.encounterIDText = encounterIDText
            self.batchSize = batchSize
            self.unit = unit
            self.discountText = discountText
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionSlotView(_ item: InteractionSlot) -> InteractionSlotView {
        return InteractionSlotView(
            code: item.code,
            name: item.name,
            encounterIDText: item.encounterID,
            batchSize: String(item.batchSize),
            unit: item.unit,
            discountText: String(format: "%.2f", item.discount),
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionSlotViews(_ items: [InteractionSlot]) -> [InteractionSlotView] {
        var views: [InteractionSlotView] = []
        for item in items {
            views.append(toInteractionSlotView(item))
        }
        return views
    }

    static func sumInteractionSlotView(_ view: InteractionSlotView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedBatchSize) + parsedDiscount
    }
}
