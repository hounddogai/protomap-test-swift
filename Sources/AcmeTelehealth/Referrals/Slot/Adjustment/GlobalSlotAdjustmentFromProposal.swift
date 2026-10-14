import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureProposalsForAdjustment(_ items: [ClosureProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveGlobalSlotAdjustmentsFromProposal(_ items: [ClosureProposal]) -> [GlobalSlotAdjustment] {
        var out: [GlobalSlotAdjustment] = []
        for item in items {
            let derived = newGlobalSlotAdjustment(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreGlobalSlotAdjustment(_ item: GlobalSlotAdjustment) -> Double {
        return defaultClosureLedgerWeight(1, active: true)
    }
}
