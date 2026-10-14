import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosurePreferencesForAssignment(_ items: [ClosurePreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveLenientSlotAssignmentsFromPreference(_ items: [ClosurePreference]) -> [LenientSlotAssignment] {
        var out: [LenientSlotAssignment] = []
        for item in items {
            let derived = newLenientSlotAssignment(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateLenientSlotAssignment(_ item: LenientSlotAssignment) -> Double {
        return rollingClosureProfileWeight(8, active: true)
    }
}
