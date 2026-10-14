import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRollingResultCyclesForMapping(_ items: [RollingResultCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveRollingPanelMappingsFromCycle(_ items: [RollingResultCycle]) -> [RollingPanelMapping] {
        var out: [RollingPanelMapping] = []
        for item in items {
            let derived = newRollingPanelMapping(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRollingPanelMapping(_ item: RollingPanelMapping) -> String {
        return normalizeRollingResultCycleCode(item.code)
    }
}
