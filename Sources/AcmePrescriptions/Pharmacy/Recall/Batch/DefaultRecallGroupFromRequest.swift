import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseRequestsForGroup(_ items: [DispenseRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultRecallGroupsFromRequest(_ items: [DispenseRequest]) -> [DefaultRecallGroup] {
        var out: [DefaultRecallGroup] = []
        for item in items {
            let derived = newDefaultRecallGroup(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileDefaultRecallGroup(_ item: DefaultRecallGroup) -> Double {
        return batchedDispensePolicyWeight(1, active: true)
    }
}
