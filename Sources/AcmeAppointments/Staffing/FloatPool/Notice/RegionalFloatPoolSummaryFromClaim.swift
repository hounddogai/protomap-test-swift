import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialClaimsForSummary(_ items: [CredentialClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRegionalFloatPoolSummariesFromClaim(_ items: [CredentialClaim]) -> [RegionalFloatPoolSummary] {
        var out: [RegionalFloatPoolSummary] = []
        for item in items {
            let derived = newRegionalFloatPoolSummary(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeRegionalFloatPoolSummary(_ item: RegionalFloatPoolSummary) -> String {
        return classifyGlobalCredentialRequest(item.weightedVolume())
    }
}
