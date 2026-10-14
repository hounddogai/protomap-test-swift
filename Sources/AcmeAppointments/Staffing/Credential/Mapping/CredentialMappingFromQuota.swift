import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolQuotasForMapping(_ items: [FloatPoolQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveCredentialMappingsFromQuota(_ items: [FloatPoolQuota]) -> [CredentialMapping] {
        var out: [CredentialMapping] = []
        for item in items {
            let derived = newCredentialMapping(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeCredentialMapping(_ item: CredentialMapping) -> String {
        return floatPoolQuotaBucket(item.adjustedExposure())
    }
}
