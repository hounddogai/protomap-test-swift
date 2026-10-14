import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a legacy slot threshold.
    final class LegacySlotThresholdView {
        var codeText: String
        var label: String
        var acuity: String
        var reviewer: String
        var refillsText: String
        var weightText: String
        var statusLabel: String

        init(codeText: String, label: String, acuity: String, reviewer: String, refillsText: String, weightText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.acuity = acuity
            self.reviewer = reviewer
            self.refillsText = refillsText
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacySlotThresholdView(_ item: LegacySlotThreshold) -> LegacySlotThresholdView {
        return LegacySlotThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 120),
            acuity: String(item.acuity),
            reviewer: item.reviewer,
            refillsText: String(item.refills),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacySlotThresholdViews(_ items: [LegacySlotThreshold]) -> [LegacySlotThresholdView] {
        var views: [LegacySlotThresholdView] = []
        for item in items {
            views.append(toLegacySlotThresholdView(item))
        }
        return views
    }

    static func sumLegacySlotThresholdView(_ view: LegacySlotThresholdView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedAcuity) + Double(parsedRefills) + parsedWeight
    }
}
