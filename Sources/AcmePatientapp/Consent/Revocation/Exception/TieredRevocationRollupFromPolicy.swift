import AcmePlatform
import Foundation

extension Consent {
    static func summarizeManualDisclosurePoliciesForRollup(_ items: [ManualDisclosurePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveTieredRevocationRollupsFromPolicy(_ items: [ManualDisclosurePolicy]) -> [TieredRevocationRollup] {
        var out: [TieredRevocationRollup] = []
        for item in items {
            let derived = newTieredRevocationRollup(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignTieredRevocationRollup(_ item: TieredRevocationRollup) -> String {
        return normalizeManualDisclosurePolicyCode(item.code)
    }
}
