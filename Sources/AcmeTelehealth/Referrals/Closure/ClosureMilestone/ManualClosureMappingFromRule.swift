import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeNetworkRulesForMappingClosureMilestone(_ items: [NetworkRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveManualClosureMappingsFromRule(_ items: [NetworkRule]) -> [ManualClosureMapping] {
        var out: [ManualClosureMapping] = []
        for item in items {
            let derived = newManualClosureMapping(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveManualClosureMapping(_ item: ManualClosureMapping) -> String {
        return normalizeAdaptiveNetworkSnapshotCode(item.code)
    }
}
