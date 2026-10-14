import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureMappingsForMapping(_ items: [ClosureMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedEligibilityMappingsFromMapping(_ items: [ClosureMapping]) -> [CappedEligibilityMapping] {
        var out: [CappedEligibilityMapping] = []
        for item in items {
            let derived = newCappedEligibilityMapping(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveCappedEligibilityMapping(_ item: CappedEligibilityMapping) -> String {
        return closureRollupBucket(item.weightedVolume())
    }
}
