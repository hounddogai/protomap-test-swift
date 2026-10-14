import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureBaselinesForCycle(_ items: [DisclosureBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveCappedWitnessCyclesFromBaseline(_ items: [DisclosureBaseline]) -> [CappedWitnessCycle] {
        var out: [CappedWitnessCycle] = []
        for item in items {
            let derived = newCappedWitnessCycle(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyCappedWitnessCycle(_ item: CappedWitnessCycle) -> Double {
        return disclosureBaselineWeight(4, active: true)
    }
}
