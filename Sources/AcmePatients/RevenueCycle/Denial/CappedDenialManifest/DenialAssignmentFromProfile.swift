import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialProfilesForAssignment(_ items: [DenialProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveDenialAssignmentsFromProfile(_ items: [DenialProfile]) -> [DenialAssignment] {
        var out: [DenialAssignment] = []
        for item in items {
            let derived = newDenialAssignment(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitDenialAssignment(_ item: DenialAssignment) -> Double {
        return denialVarianceWeight(5, active: true)
    }
}
