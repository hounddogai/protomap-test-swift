import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling rounding slot.
    final class RollingRoundingSlotView {
        var code: String
        var label: String
        var rateText: String
        var diagnosisCode: String
        var timezone: String
        var encounterIDText: String
        var budgetText: String
        var specialty: String
        var expiresAt: String
        var graceDays: String
        var allergy: String
        var statusLabel: String

        init(code: String, label: String, rateText: String, diagnosisCode: String, timezone: String, encounterIDText: String, budgetText: String, specialty: String, expiresAt: String, graceDays: String, allergy: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.rateText = rateText
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.encounterIDText = encounterIDText
            self.budgetText = budgetText
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.graceDays = graceDays
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toRollingRoundingSlotView(_ item: RollingRoundingSlot) -> RollingRoundingSlotView {
        return RollingRoundingSlotView(
            code: item.code,
            label: item.label,
            rateText: String(format: "%.2f", item.rate),
            diagnosisCode: item.diagnosisCode,
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            encounterIDText: item.encounterID,
            budgetText: String(format: "%.2f", item.budget),
            specialty: item.specialty,
            expiresAt: String(item.expiresAt),
            graceDays: String(item.graceDays),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingRoundingSlotViews(_ items: [RollingRoundingSlot]) -> [RollingRoundingSlotView] {
        var views: [RollingRoundingSlotView] = []
        for item in items {
            views.append(toRollingRoundingSlotView(item))
        }
        return views
    }

    static func sumRollingRoundingSlotView(_ view: RollingRoundingSlotView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedRate + parsedBudget + Double(parsedExpiresAt)
    }
}
