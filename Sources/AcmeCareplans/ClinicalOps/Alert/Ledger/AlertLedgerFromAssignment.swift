import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeManualHandoffAssignmentsForLedger(_ items: [ManualHandoffAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAlertLedgersFromAssignment(_ items: [ManualHandoffAssignment]) -> [AlertLedger] {
        var out: [AlertLedger] = []
        for item in items {
            let derived = newAlertLedger(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveAlertLedger(_ item: AlertLedger) -> Double {
        return adaptiveHandoffDigestWeight(9, active: true)
    }
}
