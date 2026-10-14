import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLenientDenialTargetsForQuota(_ items: [LenientDenialTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRemittanceQuotasFromTarget(_ items: [LenientDenialTarget]) -> [RemittanceQuota] {
        var out: [RemittanceQuota] = []
        for item in items {
            let derived = newRemittanceQuota(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeRemittanceQuota(_ item: RemittanceQuota) -> String {
        return denialSummaryBucket(item.weightedExposure())
    }
}
