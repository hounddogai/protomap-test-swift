import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeGlobalTaskOverridesForEstimate(_ items: [GlobalTaskOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRegionalCareProtocolEstimatesFromOverride(_ items: [GlobalTaskOverride]) -> [RegionalCareProtocolEstimate] {
        var out: [RegionalCareProtocolEstimate] = []
        for item in items {
            let derived = newRegionalCareProtocolEstimate(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyRegionalCareProtocolEstimate(_ item: RegionalCareProtocolEstimate) -> String {
        return normalizePrimaryTaskTierCode(item.code)
    }
}
