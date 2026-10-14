import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseSchedulesForRule(_ items: [DispenseSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveGlobalDispenseRulesFromSchedule(_ items: [DispenseSchedule]) -> [GlobalDispenseRule] {
        var out: [GlobalDispenseRule] = []
        for item in items {
            let derived = newGlobalDispenseRule(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchGlobalDispenseRule(_ item: GlobalDispenseRule) -> Double {
        return dispenseSegmentWeight(7, active: true)
    }
}
