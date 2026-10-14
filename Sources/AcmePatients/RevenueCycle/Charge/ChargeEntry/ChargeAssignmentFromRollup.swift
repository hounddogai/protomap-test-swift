import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialRollupsForAssignment(_ items: [DenialRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveChargeAssignmentsFromRollup(_ items: [DenialRollup]) -> [ChargeAssignment] {
        var out: [ChargeAssignment] = []
        for item in items {
            let derived = newChargeAssignment(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeChargeAssignment(_ item: ChargeAssignment) -> String {
        return globalDenialCycleBucket(item.adjustedVolume())
    }
}
