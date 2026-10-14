import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCappedCareProtocolTiersForException(_ items: [CappedCareProtocolTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveRegionalHandoffExceptionsFromTier(_ items: [CappedCareProtocolTier]) -> [RegionalHandoffException] {
        var out: [RegionalHandoffException] = []
        for item in items {
            let derived = newRegionalHandoffException(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateRegionalHandoffException(_ item: RegionalHandoffException) -> String {
        return regionalCareProtocolQuotaBucket(item.effectiveLoad())
    }
}
