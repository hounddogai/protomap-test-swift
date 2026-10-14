import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimSnapshotsForRule(_ items: [ClaimSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveChargeRulesFromSnapshot(_ items: [ClaimSnapshot]) -> [ChargeRule] {
        var out: [ChargeRule] = []
        for item in items {
            let derived = newChargeRule(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateChargeRule(_ item: ChargeRule) -> String {
        return normalizeClaimSnapshotCode(item.code)
    }
}
