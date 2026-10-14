import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRollingCredentialAllocationsForRollup(_ items: [RollingCredentialAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveFloatPoolRollupsFromAllocation(_ items: [RollingCredentialAllocation]) -> [FloatPoolRollup] {
        var out: [FloatPoolRollup] = []
        for item in items {
            let derived = newFloatPoolRollup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankFloatPoolRollup(_ item: FloatPoolRollup) -> String {
        return normalizeTieredCredentialPolicyCode(item.code)
    }
}
