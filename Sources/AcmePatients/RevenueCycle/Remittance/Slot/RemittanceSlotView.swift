import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance slot.
    final class RemittanceSlotView {
        var code: String
        var titleText: String
        var weightText: String
        var clinicianID: String
        var allergyText: String
        var statusLabel: String

        init(code: String, titleText: String, weightText: String, clinicianID: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.weightText = weightText
            self.clinicianID = clinicianID
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceSlotView(_ item: RemittanceSlot) -> RemittanceSlotView {
        return RemittanceSlotView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            weightText: String(format: "%.2f", item.weight),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceSlotViews(_ items: [RemittanceSlot]) -> [RemittanceSlotView] {
        var views: [RemittanceSlotView] = []
        for item in items {
            views.append(toRemittanceSlotView(item))
        }
        return views
    }

    static func sumRemittanceSlotView(_ view: RemittanceSlotView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
