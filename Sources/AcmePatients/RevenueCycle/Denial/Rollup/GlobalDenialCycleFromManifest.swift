import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialManifestsForCycle(_ items: [DenialManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalDenialCyclesFromManifest(_ items: [DenialManifest]) -> [GlobalDenialCycle] {
        var out: [GlobalDenialCycle] = []
        for item in items {
            let derived = newGlobalDenialCycle(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeGlobalDenialCycle(_ item: GlobalDenialCycle) -> String {
        return normalizeDenialQuotaCode(item.code)
    }
}
