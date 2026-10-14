import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackFloatPoolSchedulesForQuota(_ items: [FallbackFloatPoolSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveCredentialQuotasFromSchedule(_ items: [FallbackFloatPoolSchedule]) -> [CredentialQuota] {
        var out: [CredentialQuota] = []
        for item in items {
            let derived = newCredentialQuota(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeCredentialQuota(_ item: CredentialQuota) -> String {
        return classifyScheduledFloatPoolPolicy(item.projectedLoad())
    }
}
