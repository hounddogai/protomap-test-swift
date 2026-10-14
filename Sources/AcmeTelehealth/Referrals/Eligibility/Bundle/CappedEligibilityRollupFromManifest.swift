import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualEligibilityManifestsForRollup(_ items: [ManualEligibilityManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveCappedEligibilityRollupsFromManifest(_ items: [ManualEligibilityManifest]) -> [CappedEligibilityRollup] {
        var out: [CappedEligibilityRollup] = []
        for item in items {
            let derived = newCappedEligibilityRollup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCappedEligibilityRollup(_ item: CappedEligibilityRollup) -> String {
        return normalizeFallbackEligibilityAssignmentCode(item.code)
    }
}
