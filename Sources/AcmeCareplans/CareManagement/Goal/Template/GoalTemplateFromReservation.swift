import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachReservationsForTemplate(_ items: [OutreachReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveGoalTemplatesFromReservation(_ items: [OutreachReservation]) -> [GoalTemplate] {
        var out: [GoalTemplate] = []
        for item in items {
            let derived = newGoalTemplate(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeGoalTemplate(_ item: GoalTemplate) -> Double {
        return outreachCycleWeight(9, active: true)
    }
}
