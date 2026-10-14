import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementProfilesForTarget(_ items: [StatementProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveChargeTargetsFromProfile(_ items: [StatementProfile]) -> [ChargeTarget] {
        var out: [ChargeTarget] = []
        for item in items {
            let derived = newChargeTarget(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyChargeTarget(_ item: ChargeTarget) -> String {
        return statementClaimBucket(item.projectedVolume())
    }
}
