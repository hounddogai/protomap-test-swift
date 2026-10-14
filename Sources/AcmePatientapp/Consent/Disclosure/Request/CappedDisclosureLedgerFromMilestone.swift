import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessMilestonesForLedger(_ items: [WitnessMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedDisclosureLedgersFromMilestone(_ items: [WitnessMilestone]) -> [CappedDisclosureLedger] {
        var out: [CappedDisclosureLedger] = []
        for item in items {
            let derived = newCappedDisclosureLedger(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitCappedDisclosureLedger(_ item: CappedDisclosureLedger) -> String {
        return witnessMilestoneBucket(item.projectedValue())
    }
}
