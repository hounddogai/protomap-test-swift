import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimRecordsForEstimate(_ items: [ClaimRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRemittanceEstimatesFromRecord(_ items: [ClaimRecord]) -> [RemittanceEstimate] {
        var out: [RemittanceEstimate] = []
        for item in items {
            let derived = newRemittanceEstimate(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleRemittanceEstimate(_ item: RemittanceEstimate) -> String {
        return classifyPrimaryClaimWindow(item.projectedLoad())
    }
}
