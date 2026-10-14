import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialProposalsForProfile(_ items: [DenialProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveChargeProfilesFromProposal(_ items: [DenialProposal]) -> [ChargeProfile] {
        var out: [ChargeProfile] = []
        for item in items {
            let derived = newChargeProfile(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeChargeProfile(_ item: ChargeProfile) -> String {
        return denialAllocationBucket(item.weightedTotal())
    }
}
