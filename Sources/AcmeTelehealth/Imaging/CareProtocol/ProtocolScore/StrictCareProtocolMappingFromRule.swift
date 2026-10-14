import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRollingCareProtocolRulesForMapping(_ items: [RollingCareProtocolRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveStrictCareProtocolMappingsFromRule(_ items: [RollingCareProtocolRule]) -> [StrictCareProtocolMapping] {
        var out: [StrictCareProtocolMapping] = []
        for item in items {
            let derived = newStrictCareProtocolMapping(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeStrictCareProtocolMapping(_ item: StrictCareProtocolMapping) -> String {
        return normalizeScheduledCareProtocolSummaryCode(item.code)
    }
}
