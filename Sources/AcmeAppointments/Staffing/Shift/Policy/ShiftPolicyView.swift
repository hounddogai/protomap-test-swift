import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift policy.
    final class ShiftPolicyView {
        var code: String
        var label: String
        var startsAt: String
        var acuity: String
        var encounterID: String
        var durationMinutes: String
        var amount: String
        var rate: String
        var notes: String
        var score: String
        var ratio: String
        var statusLabel: String

        init(code: String, label: String, startsAt: String, acuity: String, encounterID: String, durationMinutes: String, amount: String, rate: String, notes: String, score: String, ratio: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.acuity = acuity
            self.encounterID = encounterID
            self.durationMinutes = durationMinutes
            self.amount = amount
            self.rate = rate
            self.notes = notes
            self.score = score
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toShiftPolicyView(_ item: ShiftPolicy) -> ShiftPolicyView {
        return ShiftPolicyView(
            code: item.code,
            label: item.label,
            startsAt: String(item.startsAt),
            acuity: String(item.acuity),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            durationMinutes: String(item.durationMinutes),
            amount: String(format: "%.2f", item.amount),
            rate: String(format: "%.2f", item.rate),
            notes: Kit.Text.truncate(item.notes, limit: 64),
            score: String(format: "%.2f", item.score),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftPolicyViews(_ items: [ShiftPolicy]) -> [ShiftPolicyView] {
        var views: [ShiftPolicyView] = []
        for item in items {
            views.append(toShiftPolicyView(item))
        }
        return views
    }

    static func sumShiftPolicyView(_ view: ShiftPolicyView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedAcuity) + Double(parsedDurationMinutes)
    }
}
