import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy credential slot.
    final class LegacyCredentialSlotView {
        var codeText: String
        var label: String
        var dosageMg: String
        var weightText: String
        var reviewer: String
        var graceDays: String
        var statusLabel: String

        init(codeText: String, label: String, dosageMg: String, weightText: String, reviewer: String, graceDays: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.dosageMg = dosageMg
            self.weightText = weightText
            self.reviewer = reviewer
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCredentialSlotView(_ item: LegacyCredentialSlot) -> LegacyCredentialSlotView {
        return LegacyCredentialSlotView(
            codeText: item.code,
            label: item.label,
            dosageMg: String(format: "%.2f", item.dosageMg),
            weightText: String(format: "%.2f", item.weight),
            reviewer: item.reviewer,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCredentialSlotViews(_ items: [LegacyCredentialSlot]) -> [LegacyCredentialSlotView] {
        var views: [LegacyCredentialSlotView] = []
        for item in items {
            views.append(toLegacyCredentialSlotView(item))
        }
        return views
    }

    static func sumLegacyCredentialSlotView(_ view: LegacyCredentialSlotView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedDosageMg + parsedWeight + Double(parsedGraceDays)
    }
}
